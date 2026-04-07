import SwiftUI
import AppKit

struct AddTransactionView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var categories = CategoryStore.shared
    @Environment(\.dismiss) private var dismiss

    var editing: Transaction?

    @State private var type: TransactionType = .expense
    @State private var amountText: String = ""
    @State private var selectedCategory: String = ""
    @State private var title: String = ""
    @State private var date: Date = .now
    @State private var memo: String = ""
    @State private var showAddCategory = false

    private var amount: Int { Int(amountText.filter(\.isNumber)) ?? 0 }
    private var isValid: Bool { amount > 0 && !selectedCategory.isEmpty }
    private var currentCategories: [CategoryItem] { categories.categories(for: type) }

    var body: some View {
        VStack(spacing: 0) {
            // ── Title bar ───────────────────────────────────────────
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

                Text(editing == nil ? "거래 추가" : "거래 수정")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)

                Spacer()

                Button {
                    saveAndDismiss()
                } label: {
                    Text(editing == nil ? "저장" : "완료")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isValid ? .white : DS.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(isValid ? DS.accent : DS.divider,
                                    in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DS.card)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 20) {
                    // Type segmented
                    HStack(spacing: 0) {
                        TypeTab(label: "지출", isSelected: type == .expense, color: DS.expense) {
                            withAnimation(.easeInOut(duration: 0.2)) { type = .expense }
                        }
                        TypeTab(label: "수입", isSelected: type == .income, color: DS.income) {
                            withAnimation(.easeInOut(duration: 0.2)) { type = .income }
                        }
                    }
                    .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                    .onChange(of: type) { _, _ in
                        if !currentCategories.map(\.name).contains(selectedCategory) {
                            selectedCategory = currentCategories.first?.name ?? ""
                        }
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Label("금액", systemImage: "wonsign")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.textSecondary)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: DS.radiusSM)
                                .fill(DS.bg)
                                .frame(height: 56)

                            HStack(alignment: .center, spacing: 4) {
                                Text("₩")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundStyle(DS.textSecondary)
                                    .fixedSize()
                                ZStack(alignment: .leading) {
                                    if amountText.isEmpty {
                                        Text("0")
                                            .font(.system(size: 30, weight: .bold).monospacedDigit())
                                            .foregroundStyle(Color(hex: "ABABAB"))
                                            .allowsHitTesting(false)
                                    }
                                    TextField("", text: $amountText)
                                        .font(.system(size: 30, weight: .bold).monospacedDigit())
                                        .foregroundStyle(type == .expense ? DS.expense : DS.income)
                                        .textFieldStyle(.plain)
                                        .minimumScaleFactor(0.6)
                                        .onChange(of: amountText) { _, new in
                                            let digits = new.filter(\.isNumber)
                                            if let n = Int(digits), n > 0 {
                                                let fmt = NumberFormatter()
                                                fmt.numberStyle = .decimal
                                                amountText = fmt.string(from: NSNumber(value: n)) ?? digits
                                            } else {
                                                amountText = ""
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("카테고리", systemImage: "tag")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.textSecondary)
                            Spacer()
                            Button {
                                showAddCategory = true
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus")
                                    Text("직접 추가")
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(DS.accent)
                            }
                            .buttonStyle(.plain)
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 72)), count: 4), spacing: 8) {
                            ForEach(currentCategories) { cat in
                                CategoryChip(
                                    item: cat,
                                    isSelected: selectedCategory == cat.name,
                                    onDelete: { categories.remove(cat, type: type) }
                                )
                                .onTapGesture { selectedCategory = cat.name }
                            }
                        }
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("날짜", systemImage: "calendar")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.textSecondary)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.light)
                            .foregroundStyle(DS.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Label("타이틀", systemImage: "text.alignleft")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.textSecondary)
                        PlaceholderTextField(placeholder: "예: 점심, 월급, 교통비…", text: $title)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                    }

                    // Memo
                    VStack(alignment: .leading, spacing: 8) {
                        Label("메모", systemImage: "note.text")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.textSecondary)
                        PlaceholderTextField(placeholder: "선택사항", text: $memo)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                    }
                }
                .padding(20)
            }
            .background(DS.card)
        }
        .frame(width: 380, height: 580)
        .background(DS.card)
        .onAppear { prefill() }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(type: type).environmentObject(store)
        }
    }

    private func saveAndDismiss() {
        // TextField 포커스 해제 → 버퍼를 바인딩에 flush한 뒤 저장
        NSApp.keyWindow?.makeFirstResponder(nil)
        let t = Transaction(
            id: editing?.id ?? UUID(),
            date: date,
            amount: amount,
            type: type,
            category: selectedCategory,
            title: title,
            memo: memo
        )
        if editing != nil { store.update(t) } else { store.add(t) }
        dismiss()
    }

    private func prefill() {
        guard let t = editing else {
            selectedCategory = categories.categories(for: type).first?.name ?? ""
            return
        }
        type     = t.type
        amountText = {
            let fmt = NumberFormatter(); fmt.numberStyle = .decimal
            return fmt.string(from: NSNumber(value: t.amount)) ?? "\(t.amount)"
        }()
        selectedCategory = t.category
        title    = t.title
        date     = t.date
        memo     = t.memo
    }
}

// MARK: - Type Tab

struct TypeTab: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? color : DS.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? DS.card : .clear,
                             in: RoundedRectangle(cornerRadius: DS.radiusSM - 1))
                .shadow(color: isSelected ? .black.opacity(0.07) : .clear, radius: 4, x: 0, y: 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(3)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let item: CategoryItem
    let isSelected: Bool
    let onDelete: () -> Void
    @State private var hovering = false

    private var isCustom: Bool {
        !CategoryStore.defaultExpenseCategories.map(\.name).contains(item.name) &&
        !CategoryStore.defaultIncomeCategories.map(\.name).contains(item.name)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Text(item.emoji).font(.system(size: 20))
                Text(item.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? DS.accent : DS.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusSM)
                    .fill(isSelected ? DS.accent.opacity(0.1) : DS.bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusSM)
                            .stroke(isSelected ? DS.accent : .clear, lineWidth: 1.5)
                    )
            )

            if hovering && isCustom {
                Button { onDelete() } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(DS.expense)
                        .font(.system(size: 14))
                        .background(DS.card, in: Circle())
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
    }
}
