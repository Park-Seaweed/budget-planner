import Foundation
import CoreXLSX

struct ExcelImportResult {
    let imported: Int
    let skipped: Int
    let sheetErrors: [String]
}

struct ExcelImporter {

    // MARK: - 색상(hex 6자리) → 카테고리 매핑

    static var colorCategoryMap: [String: String] {
        get {
            if let data = UserDefaults.standard.data(forKey: "excelColorMap"),
               let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                return dict
            }
            return defaultColorMap
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "excelColorMap")
            }
        }
    }

    static let defaultColorMap: [String: String] = [
        "BF8F00": "미용",
        "BF9000": "미용",   // FFC000(accent4) + tint -0.25 계산 오차 보정
        "70AD47": "쇼핑",
        "4472C4": "민혁",
        "ED7D31": "미용",
    ]

    // MARK: - Import

    static func importFile(from url: URL) throws -> ([Transaction], ExcelImportResult) {
        guard let file = XLSXFile(filepath: url.path) else {
            throw NSError(domain: "ExcelImporter", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "파일을 열 수 없습니다."])
        }

        let styles = try file.parseStyles()
        let shared = try file.parseSharedStrings()

        // theme palette + raw font color 해석 (theme/tint 포함)
        let themePalette = parseThemePalette(from: url)
        let fontColorMap = parseFontColors(from: url, themePalette: themePalette)


        var transactions: [Transaction] = []
        var skipped = 0
        var sheetErrors: [String] = []
        let map = colorCategoryMap

        for workbook in try file.parseWorkbooks() {
            for (name, path) in try file.parseWorksheetPathsAndNames(workbook: workbook) {
                let sheetName = name ?? ""
                guard let year = Int(sheetName.trimmingCharacters(in: CharacterSet.whitespaces)) else {
                    sheetErrors.append("'\(sheetName)' 시트: 연도 형식이 아니라 건너뜀")
                    continue
                }

                let ws = try file.parseWorksheet(at: path)
                var lastDate: Date? = nil

                for row in ws.data?.rows ?? [] {
                    let cellA = row.cells.first(where: { $0.reference.column.value == "A" })
                    let cellB = row.cells.first(where: { $0.reference.column.value == "B" })
                    let cellC = row.cells.first(where: { $0.reference.column.value == "C" })

                    // 날짜 파싱 (A열, 비어있으면 이전 날짜 유지)
                    if let aVal = cellA?.value, !aVal.isEmpty {
                        if let parsed = parseDate(aVal, year: year) {
                            lastDate = parsed
                        }
                    }

                    guard let date = lastDate else { skipped += 1; continue }

                    // 금액 파싱 (B열)
                    let rawAmount = cellB?.value ?? ""
                    let cleaned = rawAmount.replacingOccurrences(of: ",", with: "")
                                          .trimmingCharacters(in: CharacterSet.whitespaces)
                    let amountInt = Int(Double(cleaned) ?? 0)
                    guard amountInt > 0 else { skipped += 1; continue }

                    // 제목 (C열 우선 → B열)
                    let title: String
                    if let ss = shared, let c = cellC, let s = c.stringValue(ss), !s.isEmpty {
                        title = s
                    } else if let c = cellC, let v = c.value, !v.isEmpty {
                        title = v
                    } else if let ss = shared, let b = cellB, let s = b.stringValue(ss), !s.isEmpty {
                        title = s
                    } else {
                        title = cellB?.value ?? ""
                    }

                    // 카테고리: C셀 폰트색 우선 → B셀 폰트색 → 기타
                    let category = colorToCategory(cellC, styles: styles, fontColorMap: fontColorMap, map: map)
                                ?? colorToCategory(cellB, styles: styles, fontColorMap: fontColorMap, map: map)
                                ?? "기타"

                    transactions.append(Transaction(
                        date: date,
                        amount: amountInt,
                        type: .expense,
                        category: category,
                        title: title
                    ))
                }
            }
        }

        return (
            transactions,
            ExcelImportResult(
                imported: transactions.count,
                skipped: skipped,
                sheetErrors: sheetErrors
            )
        )
    }

    // MARK: - ZIP entry reader (unzip 사용, ZIPFoundation 충돌 방지)

    private static func readZipEntry(_ entry: String, from url: URL) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-p", url.path, entry]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Theme palette

    /// xl/theme/theme1.xml에서 테마 인덱스 → HEX 매핑 추출
    /// 순서: dk1(0), lt1(1), dk2(2), lt2(3), accent1(4)~accent6(9), hlink(10), folHlink(11)
    private static func parseThemePalette(from url: URL) -> [Int: String] {
        // 태그명 → 테마 인덱스 (OOXML 스펙 고정)
        let tagToIndex: [String: Int] = [
            "dk1": 0, "lt1": 1, "dk2": 2, "lt2": 3,
            "accent1": 4, "accent2": 5, "accent3": 6,
            "accent4": 7, "accent5": 8, "accent6": 9,
            "hlink": 10, "folHlink": 11
        ]
        var palette: [Int: String] = [0: "000000", 1: "FFFFFF"]
        guard let xml = readZipEntry("xl/theme/theme1.xml", from: url) else { return palette }

        // <a:TAG>...<a:srgbClr val="HEX"/>...</a:TAG> 또는 sysClr lastClr 매칭
        for (tag, idx) in tagToIndex {
            // srgbClr
            let pattern = #"<[a-z]+:\#(tag)>[^<]*<[a-z]+:srgbClr\s+val="([0-9A-Fa-f]{6})""#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let m = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
               let r = Range(m.range(at: 1), in: xml) {
                palette[idx] = String(xml[r]).uppercased()
                continue
            }
            // sysClr lastClr (dk1=검정, lt1=흰색 기본값 이미 설정됨)
            let sysPattern = #"<[a-z]+:\#(tag)>[^<]*<[a-z]+:sysClr\s[^>]*lastClr="([0-9A-Fa-f]{6})""#
            if let regex = try? NSRegularExpression(pattern: sysPattern),
               let m = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
               let r = Range(m.range(at: 1), in: xml) {
                palette[idx] = String(xml[r]).uppercased()
            }
        }
        return palette
    }

    // MARK: - Font color map

    /// xl/styles.xml의 <fonts> 섹션을 직접 파싱 → fontId → resolved HEX
    private static func parseFontColors(from url: URL, themePalette: [Int: String]) -> [Int: String] {
        guard let xml = readZipEntry("xl/styles.xml", from: url) else { return [:] }

        guard let fontBlockRegex = try? NSRegularExpression(pattern: "<font>(.*?)</font>",
                                                             options: .dotMatchesLineSeparators) else { return [:] }
        let fontMatches = fontBlockRegex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))

        var result: [Int: String] = [:]
        for (idx, match) in fontMatches.enumerated() {
            guard let blockRange = Range(match.range(at: 1), in: xml) else { continue }
            if let hex = extractColorHex(from: String(xml[blockRange]), themePalette: themePalette) {
                result[idx] = hex
            }
        }
        return result
    }

    /// font 블록에서 <color rgb="|theme="|tint=> 를 파싱해 HEX 반환
    private static func extractColorHex(from block: String, themePalette: [Int: String]) -> String? {
        // <color ... /> 추출
        guard let colorTagRegex = try? NSRegularExpression(pattern: #"<color([^/]*/?>|[^>]*>)"#),
              let colorMatch = colorTagRegex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
              let colorRange = Range(colorMatch.range, in: block) else { return nil }

        let colorTag = String(block[colorRange])

        // rgb 속성
        if let rgbRegex = try? NSRegularExpression(pattern: #"rgb="([0-9A-Fa-f]{6,8})""#),
           let m = rgbRegex.firstMatch(in: colorTag, range: NSRange(colorTag.startIndex..., in: colorTag)),
           let r = Range(m.range(at: 1), in: colorTag) {
            return normalizeHex(String(colorTag[r]))
        }

        // theme 속성
        if let themeRegex = try? NSRegularExpression(pattern: #"theme="(\d+)""#),
           let m = themeRegex.firstMatch(in: colorTag, range: NSRange(colorTag.startIndex..., in: colorTag)),
           let r = Range(m.range(at: 1), in: colorTag),
           let themeIdx = Int(colorTag[r]),
           let baseHex = themePalette[themeIdx] {

            // tint 속성
            var tint: Double = 0
            if let tintRegex = try? NSRegularExpression(pattern: #"tint="(-?[0-9.]+)""#),
               let tm = tintRegex.firstMatch(in: colorTag, range: NSRange(colorTag.startIndex..., in: colorTag)),
               let tr = Range(tm.range(at: 1), in: colorTag) {
                tint = Double(colorTag[tr]) ?? 0
            }

            return applyTint(hex: baseHex, tint: tint)
        }

        return nil
    }

    // MARK: - Color → Category

    private static func colorToCategory(
        _ cell: Cell?,
        styles: Styles,
        fontColorMap: [Int: String],
        map: [String: String]
    ) -> String? {
        guard let cell = cell,
              let fmt = cell.format(in: styles) else { return nil }

        if let hex = fontColorMap[fmt.fontId],
           let cat = map[hex] { return cat }

        return nil
    }

    /// Excel tint 적용: tint < 0이면 어둡게, tint > 0이면 밝게
    private static func applyTint(hex: String, tint: Double) -> String {
        guard hex.count == 6,
              let r = UInt8(hex.prefix(2), radix: 16),
              let g = UInt8(hex.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(hex.dropFirst(4).prefix(2), radix: 16) else { return hex }

        func blend(_ channel: UInt8) -> UInt8 {
            let c = Double(channel) / 255.0
            let result = tint < 0 ? c * (1 + tint) : c + (1 - c) * tint
            return UInt8(max(0, min(255, result * 255.0).rounded()))
        }
        return String(format: "%02X%02X%02X", blend(r), blend(g), blend(b))
    }

    private static func normalizeHex(_ rgb: String) -> String {
        (rgb.count == 8 ? String(rgb.dropFirst(2)) : rgb).uppercased()
    }

    // MARK: - Date parsing

    private static func parseDate(_ raw: String, year: Int) -> Date? {
        let cal = Calendar.current
        let parts = raw.split(separator: "-")
        if parts.count == 2, let m = Int(parts[0]), let d = Int(parts[1]) {
            var c = DateComponents(); c.year = year; c.month = m; c.day = d
            return cal.date(from: c)
        }
        if let serial = Double(raw) {
            let base = DateComponents(year: 1899, month: 12, day: 30)
            if let baseDate = cal.date(from: base) {
                return cal.date(byAdding: .day, value: Int(serial), to: baseDate)
            }
        }
        return nil
    }
}
