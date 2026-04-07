import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var categories = CategoryStore.shared

    @State private var selectedMonth: Date = Date().startOfMonth()
    @State private var typeFilter: TransactionType? = nil
    @State private var categoryFilter: String = "전체"
    @State private var showAdd = false
    @State private var editingTransaction: Transaction? = nil

    private var monthly: [Transaction] { store.transactions(for: selectedMonth) }

    private var filtered: [Transaction] {
        monthly.filter { t in
            let typeOK     = typeFilter == nil || t.type == typeFilter
            let categoryOK = categoryFilter == "전체" || t.category == categoryFilter
            return typeOK && categoryOK
        }
    }

    private var grouped: [(Date, [Transaction])] {
        let cal = Calendar.current
        return Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
            .sorted { $0.key > $1.key }
    }

    private var income:  Int { monthly.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    private var expense: Int { monthly.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var balance: Int { income - expense }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────
            VStack(spacing: 16) {
                MonthNavigator(selectedMonth: $selectedMonth)

                // Summary cards
                HStack(spacing: 12) {
                    SummaryCard(label: "수입",  amount: income,  color: DS.income)
                    SummaryCard(label: "지출",  amount: expense, color: DS.expense)
                    SummaryCard(label: "잔액",  amount: balance, color: balance >= 0 ? DS.positive : DS.warning)
                }

                // Filter bar
                HStack(spacing: 8) {
                    FilterPill(label: "전체",   isSelected: typeFilter == nil)    { typeFilter = nil }
                    FilterPill(label: "수입",   isSelected: typeFilter == .income)  { typeFilter = .income }
                    FilterPill(label: "지출",   isSelected: typeFilter == .expense) { typeFilter = .expense }

                    Spacer()

                    Menu {
                        Button("전체") { categoryFilter = "전체" }
                        Divider()
                        let cats: [CategoryItem] = typeFilter == .income
                            ? categories.incomeCategories
                            : typeFilter == .expense
                            ? categories.expenseCategories
                            : categories.incomeCategories + categories.expenseCategories
                        ForEach(cats) { c in
                            Button(c.emoji + " " + c.name) { categoryFilter = c.name }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(categoryFilter == "전체" ? "카테고리" : categoryFilter)
                                .font(.system(size: 13))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(categoryFilter == "전체" ? DS.textSecondary : DS.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(categoryFilter == "전체"
                                          ? DS.textPrimary.opacity(0.06)
                                          : DS.accent.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .background(DS.bg)

            Divider().opacity(0.4)

            // ── List ────────────────────────────────────────────────
            if filtered.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(DS.textSecondary.opacity(0.4))
                    Text("이번 달 거래 내역이 없습니다")
                        .foregroundStyle(DS.textSecondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(grouped, id: \.0) { (day, txs) in
                            Section {
                                VStack(spacing: 0) {
                                    ForEach(Array(txs.enumerated()), id: \.element.id) { idx, t in
                                        TxRow(transaction: t,
                                              isLast: idx == txs.count - 1,
                                              onEdit: { editingTransaction = t },
                                              onDelete: { store.delete(t) })
                                    }
                                }
                                .cardStyle()
                                .padding(.horizontal, 20)
                                .padding(.bottom, 4)
                            } header: {
                                HStack {
                                    Text(day.shortDate)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(DS.textSecondary)
                                    Spacer()
                                    let dayTotal = txs.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
                                    Text((dayTotal >= 0 ? "+" : "") + dayTotal.wonFormatted)
                                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                        .foregroundStyle(dayTotal >= 0 ? DS.income : DS.expense)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(DS.bg)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
                .background(DS.bg)
            }
        }
        .background(DS.bg)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text("추가")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(DS.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    CSVExporter.export(transactions: store.transactions, month: selectedMonth)
                } label: {
                    Label("CSV", systemImage: "arrow.down.doc")
                        .font(.system(size: 13))
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView().environmentObject(store)
        }
        .sheet(item: $editingTransaction) { t in
            AddTransactionView(editing: t).environmentObject(store)
        }
    }
}

// MARK: - Transaction Row

struct TxRow: View {
    let transaction: Transaction
    let isLast: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 14) {
            // Emoji badge
            ZStack {
                Circle()
                    .fill(transaction.type == .income
                          ? DS.income.opacity(0.12)
                          : DS.expense.opacity(0.10))
                    .frame(width: 40, height: 40)
                Text(CategoryStore.shared.emoji(for: transaction.category))
                    .font(.system(size: 18))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title.isEmpty ? transaction.category : transaction.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                HStack(spacing: 4) {
                    if !transaction.title.isEmpty {
                        Text(transaction.category)
                            .font(.system(size: 12))
                            .foregroundStyle(DS.textSecondary)
                    }
                    if !transaction.memo.isEmpty {
                        if !transaction.title.isEmpty { Text("·").font(.system(size: 12)).foregroundStyle(DS.textSecondary) }
                        Text(transaction.memo)
                            .font(.system(size: 12))
                            .foregroundStyle(DS.textSecondary)
                    }
                }
            }

            Spacer()

            // Amount
            Text((transaction.type == .income ? "+" : "-") + transaction.amount.wonFormatted)
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                .foregroundStyle(transaction.type == .income ? DS.income : DS.expense)

            // Hover actions
            if hovering {
                HStack(spacing: 4) {
                    Button { onEdit() } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(DS.bg, in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button { onDelete() } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.expense)
                            .frame(width: 26, height: 26)
                            .background(DS.expense.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(hovering ? DS.bg.opacity(0.6) : DS.card)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .padding(.leading, 70)
                    .opacity(0.5)
            }
        }
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
        .onTapGesture(count: 2) { onEdit() }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let label: String
    let amount: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DS.textSecondary)
            Text(amount.wonFormatted)
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .cardStyle()
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? DS.accent : DS.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(
                    isSelected ? DS.accent.opacity(0.1) : hovering ? DS.textPrimary.opacity(0.05) : .clear
                ))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
