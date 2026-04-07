import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedMonth: Date = Date().startOfMonth()
    @State private var editingCategory: String? = nil
    @State private var editAmount: String = ""

    private var expenseCategories: [CategoryItem] { CategoryStore.shared.expenseCategories }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            MonthNavigator(selectedMonth: $selectedMonth, limitToday: false)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 10) {
                    // Total budget overview
                    let totalBudget  = expenseCategories.compactMap {
                        store.budget(for: $0.name, year: selectedMonth.year, month: selectedMonth.month)?.amount
                    }.reduce(0, +)
                    let totalSpent   = expenseCategories.map { spentAmount(for: $0.name) }.reduce(0, +)

                    if totalBudget > 0 {
                        BudgetOverviewCard(totalBudget: totalBudget, totalSpent: totalSpent)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    } else {
                        Text("카테고리별 예산을 설정하면 지출 현황을 한눈에 볼 수 있어요.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .cardStyle()
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }

                    // Category rows
                    VStack(spacing: 0) {
                        ForEach(Array(expenseCategories.enumerated()), id: \.element.id) { idx, cat in
                            BudgetRowNew(
                                category: cat,
                                budget: store.budget(for: cat.name, year: selectedMonth.year, month: selectedMonth.month),
                                spent: spentAmount(for: cat.name),
                                isLast: idx == expenseCategories.count - 1,
                                onEdit: {
                                    editingCategory = cat.name
                                    let b = store.budget(for: cat.name, year: selectedMonth.year, month: selectedMonth.month)
                                    let fmt = NumberFormatter(); fmt.numberStyle = .decimal
                                    editAmount = b.map { fmt.string(from: NSNumber(value: $0.amount)) ?? "" } ?? ""
                                }
                            )
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(DS.bg)
        }
        .background(DS.bg)
        .sheet(item: Binding(
            get: { editingCategory.map { IdentifiableString(value: $0) } },
            set: { editingCategory = $0?.value }
        )) { identified in
            EditBudgetSheet(category: identified.value, month: selectedMonth, initialAmount: editAmount)
                .environmentObject(store)
        }
    }

    private func spentAmount(for category: String) -> Int {
        store.transactions(for: selectedMonth)
            .filter { $0.type == .expense && $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Overview Card

struct BudgetOverviewCard: View {
    let totalBudget: Int
    let totalSpent: Int
    private var progress: Double { min(Double(totalSpent) / Double(totalBudget), 1.0) }
    private var remaining: Int   { totalBudget - totalSpent }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("총 예산").font(.system(size: 12)).foregroundStyle(DS.textSecondary)
                    Text(totalBudget.wonFormatted)
                        .font(.system(size: 20, weight: .bold).monospacedDigit())
                        .foregroundStyle(DS.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(remaining >= 0 ? "남은 예산" : "초과 금액")
                        .font(.system(size: 12)).foregroundStyle(DS.textSecondary)
                    Text(abs(remaining).wonFormatted)
                        .font(.system(size: 20, weight: .bold).monospacedDigit())
                        .foregroundStyle(remaining >= 0 ? DS.positive : DS.expense)
                }
            }

            // Big progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.bg).frame(height: 10)
                    Capsule()
                        .fill(progress >= 1.0 ? DS.expense : progress >= 0.8 ? DS.warning : DS.positive)
                        .frame(width: geo.size.width * progress, height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Text("지출 \(totalSpent.wonFormatted)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.textSecondary)
                Spacer()
                Text("\(Int(progress * 100))% 사용")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.textSecondary)
            }
        }
        .padding(18)
        .cardStyle()
    }
}

// MARK: - Budget Row

struct BudgetRowNew: View {
    let category: CategoryItem
    let budget: Budget?
    let spent: Int
    let isLast: Bool
    let onEdit: () -> Void
    @State private var hovering = false

    private var budgetAmount: Int { budget?.amount ?? 0 }
    private var progress: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(Double(spent) / Double(budgetAmount), 1.0)
    }
    private var barColor: Color {
        progress >= 1.0 ? DS.expense : progress >= 0.8 ? DS.warning : DS.accent
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(DS.expense.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Text(category.emoji).font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.textPrimary)
                        Spacer()
                        if budgetAmount > 0 {
                            Text(spent.wonFormatted)
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .foregroundStyle(progress >= 1.0 ? DS.expense : DS.textPrimary)
                            Text("/ " + budgetAmount.wonFormatted)
                                .font(.system(size: 12).monospacedDigit())
                                .foregroundStyle(DS.textSecondary)
                        } else {
                            Text(spent > 0 ? spent.wonFormatted : "예산 미설정")
                                .font(.system(size: 13))
                                .foregroundStyle(DS.textSecondary)
                        }
                    }

                    if budgetAmount > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(DS.divider).frame(height: 5)
                                Capsule()
                                    .fill(barColor)
                                    .frame(width: geo.size.width * progress, height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                }

                if hovering {
                    Button { onEdit() } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(DS.bg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(hovering ? DS.bg.opacity(0.5) : DS.card)
            .contentShape(Rectangle())
            .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
            .onTapGesture { onEdit() }

            if !isLast { Divider().padding(.leading, 64).opacity(0.5) }
        }
    }
}

// MARK: - Edit Budget Sheet

struct EditBudgetSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let category: String
    let month: Date
    let initialAmount: String

    @State private var amountText: String = ""
    private var amount: Int { Int(amountText.filter(\.isNumber)) ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
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

                Text("\(CategoryStore.shared.emoji(for: category)) \(category) 예산")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Button("저장") {
                    store.setBudget(category: category, year: month.year, month: month.month, amount: amount)
                    dismiss()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.accent)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().opacity(0.4)

            VStack(spacing: 16) {
                Text(month.yearMonth + " 예산")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("₩").font(.system(size: 28, weight: .light)).foregroundStyle(DS.textSecondary)
                    ZStack(alignment: .leading) {
                        if amountText.isEmpty {
                            Text("0")
                                .font(.system(size: 32, weight: .bold).monospacedDigit())
                                .foregroundStyle(Color(hex: "ABABAB"))
                                .allowsHitTesting(false)
                        }
                    TextField("", text: $amountText)
                        .font(.system(size: 32, weight: .bold).monospacedDigit())
                        .foregroundStyle(DS.textPrimary)
                        .textFieldStyle(.plain)
                        .onChange(of: amountText) { _, new in
                            let digits = new.filter(\.isNumber)
                            if let n = Int(digits), n > 0 {
                                let fmt = NumberFormatter(); fmt.numberStyle = .decimal
                                amountText = fmt.string(from: NSNumber(value: n)) ?? digits
                            } else { amountText = "" }
                        }
                    }
                }
                .padding(16)
                .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))

                Button("예산 삭제") {
                    store.setBudget(category: category, year: month.year, month: month.month, amount: 0)
                    dismiss()
                }
                .font(.system(size: 13))
                .foregroundStyle(DS.expense)
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .frame(width: 320, height: 260)
        .background(DS.card)
        .onAppear { amountText = initialAmount }
    }
}

// MARK: - Helpers

struct IdentifiableString: Identifiable {
    let value: String
    var id: String { value }
}
