import SwiftUI

struct ColorMappingEditorView: View {
    @Binding var colorMap: [String: String]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var categories = CategoryStore.shared

    @State private var newHex: String  = ""
    @State private var newCategory: String = ""
    @State private var entries: [(hex: String, category: String)] = []

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(DS.bg, in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
                Text("색상 → 카테고리 매핑")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("저장") {
                    let dict = Dictionary(uniqueKeysWithValues: entries.map { ($0.hex.uppercased(), $0.category) })
                    colorMap = dict
                    ExcelImporter.colorCategoryMap = dict
                    dismiss()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.accent)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 10) {
                    // 설명
                    Text("Excel 셀 텍스트 색상의 HEX 값과 카테고리를 연결합니다.\nHEX는 6자리 (예: BF8F00)")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))

                    // 기존 항목
                    VStack(spacing: 0) {
                        ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(hexColor(entry.hex))
                                    .frame(width: 24, height: 24)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(DS.divider, lineWidth: 0.5))

                                Text("#")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(DS.textSecondary)
                                TextField("HEX", text: $entries[idx].hex)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13, design: .monospaced))
                                    .frame(width: 80)
                                    .onChange(of: entries[idx].hex) { _, new in
                                        entries[idx].hex = new.uppercased().filter { "0123456789ABCDEF".contains($0) }.prefix(6).description
                                    }

                                Text("→").foregroundStyle(DS.textSecondary)

                                Menu {
                                    let all = categories.expenseCategories + categories.incomeCategories
                                    ForEach(all) { cat in
                                        Button(cat.emoji + " " + cat.name) { entries[idx].category = cat.name }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(entries[idx].category.isEmpty ? "카테고리 선택" : entries[idx].category)
                                            .font(.system(size: 13))
                                            .foregroundStyle(entries[idx].category.isEmpty ? DS.textSecondary : DS.textPrimary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 10))
                                            .foregroundStyle(DS.textSecondary)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button {
                                    entries.remove(at: idx)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(DS.expense)
                                        .font(.system(size: 16))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                            if idx < entries.count - 1 {
                                Divider().padding(.leading, 16).opacity(0.4)
                            }
                        }
                    }
                    .cardStyle()

                    // 새 항목 추가
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hexColor(newHex))
                            .frame(width: 24, height: 24)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(DS.divider, lineWidth: 0.5))

                        Text("#").font(.system(size: 13, design: .monospaced)).foregroundStyle(DS.textSecondary)
                        TextField("BF8F00", text: $newHex)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(width: 80)
                            .onChange(of: newHex) { _, new in
                                newHex = new.uppercased().filter { "0123456789ABCDEF".contains($0) }.prefix(6).description
                            }

                        Text("→").foregroundStyle(DS.textSecondary)

                        Menu {
                            let all = categories.expenseCategories + categories.incomeCategories
                            ForEach(all) { cat in
                                Button(cat.emoji + " " + cat.name) { newCategory = cat.name }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(newCategory.isEmpty ? "카테고리 선택" : newCategory)
                                    .font(.system(size: 13))
                                    .foregroundStyle(newCategory.isEmpty ? DS.textSecondary : DS.textPrimary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.textSecondary)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            guard newHex.count == 6, !newCategory.isEmpty else { return }
                            entries.append((hex: newHex, category: newCategory))
                            newHex = ""; newCategory = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(newHex.count == 6 && !newCategory.isEmpty ? DS.accent : DS.textSecondary)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                        .disabled(newHex.count != 6 || newCategory.isEmpty)
                    }
                    .padding(14)
                    .cardStyle()
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 540)
        .background(DS.card)
        .onAppear {
            entries = colorMap.sorted(by: { $0.key < $1.key }).map { (hex: $0.key, category: $0.value) }
        }
    }

    private func hexColor(_ hex: String) -> Color {
        hex.count == 6 ? Color(hex: hex) : Color.clear
    }
}
