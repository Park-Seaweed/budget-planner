import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var updater: UpdaterViewModel

    @State private var mode: StorageMode   = StorageSettings.mode
    @State private var s3AccessKey: String = StorageSettings.s3AccessKey
    @State private var s3SecretKey: String = StorageSettings.s3SecretKey
    @State private var s3Bucket: String    = StorageSettings.s3Bucket
    @State private var s3Region: String    = StorageSettings.s3Region
    @State private var s3Key: String       = StorageSettings.s3Key
    @State private var isTesting           = false
    @State private var testResult: String? = nil

    // Excel import
    @State private var isImporting        = false
    @State private var importResult: String? = nil
    @State private var showImportResult   = false
    @State private var colorMap: [String: String] = ExcelImporter.colorCategoryMap
    @State private var showColorEditor    = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Storage mode
                SettingSection(title: "저장 방식") {
                    HStack(spacing: 0) {
                        ForEach(StorageMode.allCases, id: \.self) { m in
                            Button {
                                mode = m
                                StorageSettings.mode = m
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: m == .local ? "internaldrive" : "cloud")
                                        .font(.system(size: 13))
                                    Text(m.label)
                                        .font(.system(size: 13, weight: mode == m ? .semibold : .regular))
                                }
                                .foregroundStyle(mode == m ? DS.accent : DS.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(mode == m ? DS.card : .clear,
                                            in: RoundedRectangle(cornerRadius: DS.radiusSM - 1))
                                .shadow(color: mode == m ? .black.opacity(0.07) : .clear, radius: 4, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                            .padding(3)
                        }
                    }
                    .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))

                    if mode == .local {
                        HStack {
                            Image(systemName: "folder").foregroundStyle(DS.textSecondary)
                            Text("~/Documents/가계부/data.json")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(DS.textSecondary)
                            Spacer()
                            Button("Finder에서 열기") {
                                let storage = LocalFileStorage()
                                let url = URL(fileURLWithPath: storage.filePath)
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                            .font(.system(size: 12))
                            .buttonStyle(.link)
                        }
                        .padding(12)
                        .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                    }
                }

                // S3 settings
                if mode == .s3 {
                    SettingSection(title: "Amazon S3 설정") {
                        VStack(spacing: 10) {
                            S3Field(label: "Access Key ID",   placeholder: "AKIA...",            text: $s3AccessKey, onChange: { StorageSettings.s3AccessKey = $0 })
                            S3Field(label: "Secret Access Key", placeholder: "••••••••",         text: $s3SecretKey, onChange: { StorageSettings.s3SecretKey = $0 }, isSecure: true)
                            S3Field(label: "버킷 이름",          placeholder: "my-budget-bucket",  text: $s3Bucket,    onChange: { StorageSettings.s3Bucket = $0 })
                            S3Field(label: "리전",             placeholder: "ap-northeast-2",     text: $s3Region,    onChange: { StorageSettings.s3Region = $0 })
                            S3Field(label: "파일 키",           placeholder: "gakyebu/data.json", text: $s3Key,       onChange: { StorageSettings.s3Key = $0 })

                            HStack {
                                if isTesting { ProgressView().scaleEffect(0.7) }
                                if let r = testResult {
                                    Text(r)
                                        .font(.system(size: 12))
                                        .foregroundStyle(r.hasPrefix("✅") ? DS.positive : DS.expense)
                                }
                                Spacer()
                                Button("연결 테스트") {
                                    Task { await testS3() }
                                }
                                .disabled(s3Bucket.isEmpty || s3AccessKey.isEmpty || isTesting)
                                .buttonStyle(.bordered)
                                .font(.system(size: 13))
                            }
                        }
                    }
                }

                // Data actions
                SettingSection(title: "데이터") {
                    VStack(spacing: 8) {
                        ActionRow(icon: "arrow.up.doc", label: "지금 저장", color: DS.accent)  { store.save() }
                        Divider().opacity(0.4)
                        ActionRow(icon: "arrow.clockwise", label: "다시 불러오기", color: DS.accent) { Task { await store.reload() } }
                        Divider().opacity(0.4)
                        ActionRow(icon: "tablecells", label: "전체 CSV 내보내기", color: DS.positive) {
                            CSVExporter.export(transactions: store.transactions)
                        }
                    }
                }

                // Excel import
                SettingSection(title: "Excel 가져오기") {
                    VStack(alignment: .leading, spacing: 14) {
                        // 설명
                        VStack(alignment: .leading, spacing: 6) {
                            Text("지원 형식: .xlsx")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(DS.textPrimary)
                            Text("시트명 = 연도 (예: 2025)\nA열: 날짜(MM-DD), B열: 금액, C열: 내용\n셀 색상으로 카테고리 자동 분류")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))

                        // 색상 매핑 표
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("색상 → 카테고리 매핑")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(DS.textSecondary)
                                Spacer()
                                Button("편집") { showColorEditor = true }
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.accent)
                                    .buttonStyle(.plain)
                            }
                            ForEach(Array(colorMap.sorted(by: { $0.key < $1.key })), id: \.key) { hex, cat in
                                HStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: hex))
                                        .frame(width: 20, height: 20)
                                    Text("#" + hex)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(DS.textSecondary)
                                    Text("→")
                                        .foregroundStyle(DS.textSecondary)
                                    Text(cat)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(DS.textPrimary)
                                }
                            }
                        }

                        // 가져오기 버튼
                        HStack {
                            if isImporting { ProgressView().scaleEffect(0.8) }
                            Spacer()
                            Button {
                                pickAndImport()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.badge.plus")
                                    Text("Excel 파일 선택")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(DS.accent, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                            }
                            .buttonStyle(.plain)
                            .disabled(isImporting)
                        }
                    }
                }
                // 앱 정보 & 업데이트
                SettingSection(title: "앱 정보") {
                    VStack(spacing: 0) {
                        HStack {
                            Text("버전")
                                .font(.system(size: 13))
                                .foregroundStyle(DS.textPrimary)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                                .font(.system(size: 13, weight: .medium).monospacedDigit())
                                .foregroundStyle(DS.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                        Divider().opacity(0.4)

                        HStack {
                            Text("업데이트 확인")
                                .font(.system(size: 13))
                                .foregroundStyle(DS.textPrimary)
                            Spacer()
                            Button("지금 확인") {
                                updater.checkForUpdates()
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(updater.canCheckForUpdates ? DS.accent : DS.textSecondary)
                            .buttonStyle(.plain)
                            .disabled(!updater.canCheckForUpdates)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(20)
        }
        .background(DS.bg)
        .alert("가져오기 완료", isPresented: $showImportResult) {
            Button("확인") {}
        } message: {
            Text(importResult ?? "")
        }
        .sheet(isPresented: $showColorEditor) {
            ColorMappingEditorView(colorMap: $colorMap)
        }
    }

    private func pickAndImport() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "xlsx")!]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Excel 파일을 선택하세요"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        isImporting = true
        Task {
            do {
                let (txs, result) = try ExcelImporter.importFile(from: url)
                await MainActor.run {
                    // 없는 카테고리 자동 생성
                    let store2 = CategoryStore.shared
                    let allNames = Set((store2.expenseCategories + store2.incomeCategories).map { $0.name })
                    let newCats = Set(txs.map { $0.category }).subtracting(allNames).subtracting(["기타"])
                    for cat in newCats {
                        store2.add(name: cat, emoji: "📌", type: .expense)
                    }

                    store.bulkAdd(txs)
                    var msg = "✅ \(result.imported)건 가져오기 완료"
                    if result.skipped > 0 { msg += "\n건너뜀: \(result.skipped)건" }
                    if !result.sheetErrors.isEmpty { msg += "\n⚠️ " + result.sheetErrors.joined(separator: "\n") }
                    importResult = msg
                    showImportResult = true
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importResult = "❌ 오류: \(error.localizedDescription)"
                    showImportResult = true
                    isImporting = false
                }
            }
        }
    }

    private func testS3() async {
        isTesting = true; testResult = nil
        let s3 = S3Storage(
            accessKey: s3AccessKey, secretKey: s3SecretKey,
            bucket: s3Bucket, region: s3Region, objectKey: s3Key
        )
        do {
            _ = try await s3.load()
            testResult = "✅ 연결 성공"
        } catch {
            testResult = "❌ \(error.localizedDescription)"
        }
        isTesting = false
    }
}

// MARK: - Helpers

struct SettingSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.textSecondary)
                .padding(.horizontal, 4)
            content()
                .padding(16)
                .cardStyle()
        }
    }
}

struct S3Field: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let onChange: (String) -> Void
    var isSecure: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(DS.textSecondary)
                .frame(width: 130, alignment: .leading)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onChange(of: text) { _, v in onChange(v) }
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onChange(of: text) { _, v in onChange(v) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
    }
}

struct ActionRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.textSecondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
