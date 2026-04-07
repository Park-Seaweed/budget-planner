import Foundation
import AppKit

struct CSVExporter {
    static func export(transactions: [Transaction], month: Date? = nil) {
        let rows = month == nil ? transactions : transactions.filter { t in
            t.date.year == month!.year && t.date.month == month!.month
        }
        let sorted = rows.sorted { $0.date < $1.date }

        var lines = ["날짜,유형,카테고리,금액,메모"]
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        for t in sorted {
            let line = [
                fmt.string(from: t.date),
                t.type.label,
                t.category,
                "\(t.amount)",
                t.memo.replacingOccurrences(of: ",", with: " ")
            ].joined(separator: ",")
            lines.append(line)
        }

        let csv = lines.joined(separator: "\n")

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true
        if let month {
            panel.nameFieldStringValue = "가계부_\(month.year)년\(month.month)월.csv"
        } else {
            panel.nameFieldStringValue = "가계부_전체.csv"
        }
        panel.title = "CSV로 내보내기"

        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8WithBOM)
        }
    }
}

private extension String.Encoding {
    static let utf8WithBOM = String.Encoding(rawValue: 0x8000_0100)  // UTF-8 BOM (Excel 호환)
}
