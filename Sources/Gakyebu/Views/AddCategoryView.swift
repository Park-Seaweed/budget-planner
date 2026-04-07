import SwiftUI

struct AddCategoryView: View {
    let type: TransactionType
    @ObservedObject var categories = CategoryStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name: String  = ""
    @State private var emoji: String = ""

    private let suggestions = ["🏷️","🎁","🌟","🍀","🔑","🎵","🎮","🏋️","✈️","🍕",
                               "🥗","🎉","🏆","💡","🧴","🧹","🐶","🐱","🌈","🚀",
                               "🎨","🛒","⚽","📷","🎸","🏖️","🧃","💇","🪴","🎓"]

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !emoji.isEmpty }

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
                Text("카테고리 추가")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("추가") {
                    categories.add(name: name.trimmingCharacters(in: .whitespaces), emoji: emoji, type: type)
                    dismiss()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isValid ? DS.accent : DS.textSecondary)
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DS.card)

            Divider().opacity(0.4)

            VStack(spacing: 20) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("카테고리 이름")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                    PlaceholderTextField(placeholder: "예: 반려동물, 구독서비스…", text: $name, font: .system(size: 15))
                        .padding(12)
                        .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                }

                // Emoji
                VStack(alignment: .leading, spacing: 8) {
                    Text("이모지")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)

                    // Selected emoji large display
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(DS.bg)
                                .frame(width: 52, height: 52)
                            Text(emoji.isEmpty ? "?" : emoji)
                                .font(.system(size: 28))
                                .foregroundStyle(emoji.isEmpty ? DS.textSecondary.opacity(0.3) : .primary)
                        }
                        TextField("이모지 직접 입력", text: $emoji)
                            .textFieldStyle(.plain)
                            .font(.system(size: 20))
                            .padding(12)
                            .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                            .onChange(of: emoji) { _, new in
                                if new.count > 1 { emoji = String(new.prefix(1)) }
                            }
                    }

                    // Grid suggestions
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 8) {
                        ForEach(suggestions, id: \.self) { e in
                            Text(e)
                                .font(.system(size: 20))
                                .frame(width: 38, height: 38)
                                .background(emoji == e
                                            ? DS.accent.opacity(0.15)
                                            : DS.bg,
                                            in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(emoji == e ? DS.accent : .clear, lineWidth: 1.5))
                                .onTapGesture { emoji = e }
                        }
                    }
                }

                // Preview
                if isValid {
                    HStack(spacing: 10) {
                        Image(systemName: "eye").foregroundStyle(DS.textSecondary).font(.system(size: 12))
                        Text("미리보기").font(.system(size: 12)).foregroundStyle(DS.textSecondary)
                        Spacer()
                        Text(emoji + " " + name)
                            .font(.system(size: 14, weight: .medium))
                        Text("·")
                        Text(type.label)
                            .font(.system(size: 12))
                            .foregroundStyle(type == .expense ? DS.expense : DS.income)
                    }
                    .padding(12)
                    .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                }
            }
            .padding(20)
            .background(DS.card)
        }
        .frame(width: 360, height: 500)
        .background(DS.card)
    }
}
