import SwiftUI
import Charts

enum StatsPeriod: String, CaseIterable, Identifiable {
    case weekly  = "주별"
    case monthly = "월별"
    case yearly  = "연별"
    var id: String { rawValue }
}

struct StatsView: View {
    @EnvironmentObject var store: AppStore
    @State private var period: StatsPeriod = .monthly
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private var availableYears: [Int] {
        let allYears = Set(store.transactions.map { $0.date.year })
        return Array(allYears).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Picker("", selection: $period) {
                        ForEach(StatsPeriod.allCases) { p in Text(p.rawValue).tag(p) }
                    }
                    .pickerStyle(.segmented)
                    .colorScheme(.light)
                    .frame(width: 240)

                    Spacer()

                    if period == .monthly {
                        HStack(spacing: 12) {
                            Button { selectedYear -= 1 } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(DS.textPrimary)
                                    .frame(width: 28, height: 28)
                                    .background(DS.card, in: Circle())
                                    .overlay(Circle().stroke(DS.divider, lineWidth: 0.5))
                            }.buttonStyle(.plain)

                            Menu {
                                ForEach(availableYears.reversed(), id: \.self) { y in
                                    Button(String(y) + "년") { selectedYear = y }
                                }
                            } label: {
                                Text(String(selectedYear) + "년")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(DS.textPrimary)
                                    .frame(minWidth: 60)
                            }
                            .buttonStyle(.plain)

                            Button {
                                selectedYear += 1
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(DS.textPrimary)
                                    .frame(width: 28, height: 28)
                                    .background(DS.card, in: Circle())
                                    .overlay(Circle().stroke(DS.divider, lineWidth: 0.5))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 20)
                .onAppear {
                    if let latest = availableYears.last {
                        selectedYear = latest
                    }
                }

                switch period {
                case .weekly:  WeeklyStatsView()
                case .monthly: MonthlyStatsView(year: selectedYear)
                case .yearly:  YearlyStatsView()
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(DS.bg)
    }
}

// MARK: - Weekly

struct WeeklyStatsView: View {
    @EnvironmentObject var store: AppStore
    @State private var baseOffset: Int = 0
    @State private var compareOffset: Int? = nil

    // 가장 오래된 거래일 기준으로 최대 주 수 계산
    private var maxWeeks: Int {
        let cal = Calendar.current
        guard let oldest = store.transactions.map({ $0.date }).min() else { return 4 }
        let today = cal.startOfWeek(for: Date())
        let diff = cal.dateComponents([.weekOfYear], from: oldest, to: today).weekOfYear ?? 0
        return max(diff + 1, 4)
    }

    private func weekStart(offset: Int) -> Date {
        let cal = Calendar.current
        return cal.date(byAdding: .weekOfYear, value: -offset, to: cal.startOfWeek(for: Date())) ?? Date()
    }

    private func weekData(offset: Int) -> (label: String, data: PeriodData) {
        let cal = Calendar.current
        let ws = weekStart(offset: offset)
        let we = cal.date(byAdding: .day, value: 6, to: ws) ?? ws
        let txs = store.transactions.filter { $0.date >= ws && $0.date <= we }
        let fmt = DateFormatter(); fmt.dateFormat = "M/d"
        let label = fmt.string(from: ws) + "~" + fmt.string(from: we)
        return (label, PeriodData(
            label: label,
            income:  txs.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount },
            expense: txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        ))
    }

    private func weekPickerLabel(_ offset: Int) -> String {
        let cal = Calendar.current
        let ws = weekStart(offset: offset)
        let we = cal.date(byAdding: .day, value: 6, to: ws) ?? ws
        let fmt = DateFormatter(); fmt.dateFormat = "M/d"
        if offset == 0 { return "이번 주 (" + fmt.string(from: ws) + ")" }
        if offset == 1 { return "저번 주 (" + fmt.string(from: ws) + ")" }
        return fmt.string(from: ws) + "~" + fmt.string(from: we)
    }

    private var offsetsByYear: [(year: Int, offsets: [Int])] {
        let cal = Calendar.current
        var dict: [Int: [Int]] = [:]
        for i in 0..<maxWeeks {
            let y = cal.component(.year, from: weekStart(offset: i))
            dict[y, default: []].append(i)
        }
        return dict.keys.sorted(by: >).map { y in (year: y, offsets: dict[y]!) }
    }

    var body: some View {
        let base = weekData(offset: baseOffset)
        let comp = compareOffset.map { weekData(offset: $0) }

        VStack(spacing: 16) {
            periodSelector
            if let comp = comp {
                comparisonView(base: base.data, comp: comp.data)
            } else {
                singleView(data: base.data, title: base.label + " 수입/지출")
            }
        }
    }

    private var periodSelector: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("기준 주").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary)
                Menu {
                    ForEach(offsetsByYear, id: \.year) { group in
                        Menu(String(group.year) + "년") {
                            ForEach(group.offsets, id: \.self) { i in
                                Button(weekPickerLabel(i)) { baseOffset = i }
                            }
                        }
                    }
                } label: {
                    menuLabel(weekPickerLabel(baseOffset))
                }
                .buttonStyle(.plain)
            }

            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 13))
                .foregroundStyle(DS.textSecondary)
                .padding(.top, 18)

            VStack(alignment: .leading, spacing: 4) {
                Text("비교 주").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary)
                Menu {
                    Button("비교 안 함") { compareOffset = nil }
                    Divider()
                    ForEach(offsetsByYear, id: \.year) { group in
                        Menu(String(group.year) + "년") {
                            ForEach(group.offsets.filter { $0 != baseOffset }, id: \.self) { i in
                                Button(weekPickerLabel(i)) { compareOffset = i }
                            }
                        }
                    }
                } label: {
                    menuLabel(compareOffset.map { weekPickerLabel($0) } ?? "비교 안 함", isPlaceholder: compareOffset == nil)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Monthly

struct MonthlyStatsView: View {
    @EnvironmentObject var store: AppStore
    let year: Int
    @State private var baseYear: Int = Calendar.current.component(.year, from: Date())
    @State private var baseMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var compareYear: Int? = nil
    @State private var compareMonth: Int? = nil

    private func monthData(year: Int, month: Int) -> PeriodData {
        let txs = store.transactions.filter { $0.date.year == year && $0.date.month == month }
        return PeriodData(
            label: String(year) + "년 \(month)월",
            income:  txs.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount },
            expense: txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        )
    }

    private var availableYears: [Int] {
        Array(Set(store.transactions.map { $0.date.year })).sorted()
    }

    private var categoryBreakdown: [CategoryData] {
        let exp = store.transactions.filter { $0.date.year == baseYear && $0.type == .expense }
        let total = exp.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }
        var dict: [String: Int] = [:]
        for t in exp { dict[t.category, default: 0] += t.amount }
        return dict.map { CategoryData(category: $0.key, amount: $0.value, total: total) }.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        let base = monthData(year: baseYear, month: baseMonth)
        let hasCompare = compareYear != nil && compareMonth != nil
        let comp: PeriodData? = hasCompare ? monthData(year: compareYear!, month: compareMonth!) : nil

        VStack(spacing: 16) {
            periodSelector

            if let comp = comp {
                comparisonView(base: base, comp: comp)
            } else {
                singleView(data: base, title: String(baseYear) + "년 \(baseMonth)월 수입/지출")
                if !categoryBreakdown.isEmpty {
                    categoryDonut(data: categoryBreakdown, title: String(baseYear) + "년 카테고리별 지출")
                }
            }
        }
        .onAppear {
            baseYear = year
        }
        .onChange(of: year) { baseYear = $0 }
    }

    private var periodSelector: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("기준 월").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary)
                Menu {
                    ForEach(availableYears, id: \.self) { y in
                        Menu(String(y) + "년") {
                            ForEach(1...12, id: \.self) { m in
                                Button("\(m)월") { baseYear = y; baseMonth = m }
                            }
                        }
                    }
                } label: {
                    menuLabel(String(baseYear) + "년 \(baseMonth)월")
                }
                .buttonStyle(.plain)
            }

            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 13))
                .foregroundStyle(DS.textSecondary)
                .padding(.top, 18)

            VStack(alignment: .leading, spacing: 4) {
                Text("비교 월").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary)
                Menu {
                    Button("비교 안 함") { compareYear = nil; compareMonth = nil }
                    Divider()
                    let prevM = baseMonth == 1 ? 12 : baseMonth - 1
                    let prevY = baseMonth == 1 ? baseYear - 1 : baseYear
                    Button("전월 (\(String(prevY))년 \(prevM)월)") { compareYear = prevY; compareMonth = prevM }
                    Button("전년 동월 (\(String(baseYear-1))년 \(baseMonth)월)") { compareYear = baseYear - 1; compareMonth = baseMonth }
                    Divider()
                    ForEach(availableYears, id: \.self) { y in
                        Menu(String(y) + "년") {
                            ForEach(1...12, id: \.self) { m in
                                Button("\(m)월") { compareYear = y; compareMonth = m }
                            }
                        }
                    }
                } label: {
                    let label = (compareYear != nil && compareMonth != nil)
                        ? String(compareYear!) + "년 \(compareMonth!)월"
                        : "비교 안 함"
                    menuLabel(label, isPlaceholder: compareYear == nil)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Yearly

struct YearlyStatsView: View {
    @EnvironmentObject var store: AppStore
    @State private var baseYear: Int = Calendar.current.component(.year, from: Date())
    @State private var compareYear: Int? = nil

    private var availableYears: [Int] {
        Array(Set(store.transactions.map { $0.date.year })).sorted()
    }

    private func initBaseYear() {
        if !availableYears.contains(baseYear), let latest = availableYears.last {
            baseYear = latest
        }
    }

    private func yearData(_ year: Int) -> PeriodData {
        let txs = store.transactions.filter { $0.date.year == year }
        return PeriodData(
            label: String(year) + "년",
            income:  txs.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount },
            expense: txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        )
    }

    var body: some View {
        if availableYears.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "chart.bar").font(.system(size: 36)).foregroundStyle(DS.textSecondary.opacity(0.3))
                Text("거래 내역이 없습니다").foregroundStyle(DS.textSecondary)
            }
            .frame(maxWidth: .infinity).padding(48).cardStyle()
        } else {
            let base = yearData(baseYear)
            let comp: PeriodData? = compareYear.map { yearData($0) }

            VStack(spacing: 16) {
                periodSelector

                if let comp = comp {
                    comparisonView(base: base, comp: comp)
                } else {
                    let allRows = availableYears.map { yearData($0) }
                    singleView(data: base, title: String(baseYear) + "년 수입/지출", allRows: allRows)
                }
            }
            .onAppear { initBaseYear() }
        }
    }

    private var periodSelector: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("기준 연도").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary)
                Menu {
                    ForEach(availableYears, id: \.self) { y in
                        Button(String(y) + "년") { baseYear = y }
                    }
                } label: {
                    menuLabel(String(baseYear) + "년")
                }
                .buttonStyle(.plain)
            }

            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 13))
                .foregroundStyle(DS.textSecondary)
                .padding(.top, 18)

            VStack(alignment: .leading, spacing: 4) {
                Text("비교 연도").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary)
                Menu {
                    Button("비교 안 함") { compareYear = nil }
                    Divider()
                    ForEach(availableYears.filter { $0 != baseYear }, id: \.self) { y in
                        Button(String(y) + "년") { compareYear = y }
                    }
                } label: {
                    menuLabel(compareYear.map { String($0) + "년" } ?? "비교 안 함", isPlaceholder: compareYear == nil)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Shared: single view

private func singleView(data: PeriodData, title: String, allRows: [PeriodData]? = nil) -> some View {
    let rows = allRows ?? [data]
    return VStack(spacing: 16) {
        HStack(spacing: 12) {
            StatMiniCard(title: "수입",  value: data.income,                  color: DS.income)
            StatMiniCard(title: "지출",  value: data.expense,                 color: DS.expense)
            StatMiniCard(title: "순수익", value: data.income - data.expense,   color: data.income >= data.expense ? DS.positive : DS.warning)
        }
        barChart(rows: rows, title: title)
        periodTable(rows: rows)
    }
}

// MARK: - Shared: comparison view

private func comparisonView(base: PeriodData, comp: PeriodData) -> some View {
    let diffIncome  = base.income  - comp.income
    let diffExpense = base.expense - comp.expense
    let diffBalance = (base.income - base.expense) - (comp.income - comp.expense)

    return VStack(spacing: 16) {
        // 비교 요약 카드
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Text("").frame(maxWidth: .infinity)
                Text(base.label).font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.accent).frame(width: 110, alignment: .trailing)
                Text(comp.label).font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary).frame(width: 110, alignment: .trailing)
                Text("증감").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary).frame(width: 100, alignment: .trailing)
            }
            .padding(.horizontal, 16).padding(.top, 12)

            Divider().opacity(0.5)

            compareRow(label: "수입", baseVal: base.income, compVal: comp.income, diff: diffIncome, color: DS.income)
            Divider().padding(.leading, 16).opacity(0.4)
            compareRow(label: "지출", baseVal: base.expense, compVal: comp.expense, diff: diffExpense, color: DS.expense, invertSign: true)
            Divider().padding(.leading, 16).opacity(0.4)
            compareRow(label: "순수익", baseVal: base.income - base.expense, compVal: comp.income - comp.expense, diff: diffBalance, color: diffBalance >= 0 ? DS.positive : DS.warning)
        }
        .cardStyle()

        // 비교 바 차트
        comparisonBarChart(base: base, comp: comp)
    }
}

private func compareRow(label: String, baseVal: Int, compVal: Int, diff: Int, color: Color, invertSign: Bool = false) -> some View {
    let positive = invertSign ? diff <= 0 : diff >= 0
    let diffColor: Color = diff == 0 ? DS.textSecondary : positive ? DS.positive : DS.expense
    let arrow = diff == 0 ? "" : diff > 0 ? "▲" : "▼"

    return HStack(spacing: 0) {
        Text(label).font(.system(size: 13)).foregroundStyle(DS.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
        Text(baseVal.wonFormatted).font(.system(size: 13, weight: .semibold).monospacedDigit()).foregroundStyle(color).frame(width: 110, alignment: .trailing)
        Text(compVal.wonFormatted).font(.system(size: 13).monospacedDigit()).foregroundStyle(DS.textSecondary).frame(width: 110, alignment: .trailing)
        Text(diff == 0 ? "-" : arrow + abs(diff).wonFormatted)
            .font(.system(size: 12, weight: .semibold).monospacedDigit())
            .foregroundStyle(diffColor)
            .frame(width: 100, alignment: .trailing)
    }
    .padding(.horizontal, 16).padding(.vertical, 10)
}

private func comparisonBarChart(base: PeriodData, comp: PeriodData) -> some View {
    let items: [CompBar] = [
        CompBar(category: "수입",  period: base.label, amount: base.income),
        CompBar(category: "수입",  period: comp.label, amount: comp.income),
        CompBar(category: "지출",  period: base.label, amount: base.expense),
        CompBar(category: "지출",  period: comp.label, amount: comp.expense),
    ]

    return VStack(alignment: .leading, spacing: 12) {
        Text("기간 비교").font(.system(size: 14, weight: .semibold)).foregroundStyle(DS.textPrimary)
        Chart(items) { item in
            BarMark(x: .value("항목", item.category), y: .value("금액", item.amount))
                .foregroundStyle(by: .value("기간", item.period))
                .cornerRadius(4)
                .position(by: .value("기간", item.period), span: .ratio(0.6))
        }
        .chartForegroundStyleScale([base.label: DS.accent, comp.label: DS.textSecondary.opacity(0.5)])
        .chartLegend(position: .topTrailing)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(DS.divider)
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text(shortWon(v)).font(.system(size: 10)).foregroundStyle(DS.textSecondary)
                    }
                }
            }
        }
        .frame(height: 200)
    }
    .padding(16).cardStyle()
}

// MARK: - Shared builders

private func barChart(rows: [PeriodData], title: String) -> some View {
    let flat = rows.flatMap { r in [
        FlatBar(label: r.label, kind: "수입", amount: r.income),
        FlatBar(label: r.label, kind: "지출", amount: r.expense)
    ]}
    return VStack(alignment: .leading, spacing: 12) {
        Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(DS.textPrimary)
        Chart(flat) { item in
            BarMark(x: .value("기간", item.label), y: .value("금액", item.amount))
                .foregroundStyle(by: .value("유형", item.kind))
                .cornerRadius(3)
                .position(by: .value("유형", item.kind), span: .ratio(0.7))
        }
        .chartForegroundStyleScale(["수입": DS.income, "지출": DS.expense])
        .chartLegend(position: .topTrailing)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(DS.divider)
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text(shortWon(v)).font(.system(size: 10)).foregroundStyle(DS.textSecondary)
                    }
                }
            }
        }
        .frame(height: 200)
    }
    .padding(16).cardStyle()
}

private func periodTable(rows: [PeriodData]) -> some View {
    VStack(spacing: 0) {
        HStack {
            Text("기간").frame(maxWidth: .infinity, alignment: .leading)
            Text("수입").frame(width: 110, alignment: .trailing)
            Text("지출").frame(width: 110, alignment: .trailing)
            Text("잔액").frame(width: 110, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.textSecondary)
        .padding(.horizontal, 16).padding(.vertical, 10).background(DS.bg)

        Divider().opacity(0.5)

        ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
            let balance = row.income - row.expense
            VStack(spacing: 0) {
                HStack {
                    Text(row.label).font(.system(size: 13)).foregroundStyle(DS.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.income  > 0 ? row.income.wonFormatted  : "-").font(.system(size: 13).monospacedDigit()).foregroundStyle(DS.income).frame(width: 110, alignment: .trailing)
                    Text(row.expense > 0 ? row.expense.wonFormatted : "-").font(.system(size: 13).monospacedDigit()).foregroundStyle(DS.expense).frame(width: 110, alignment: .trailing)
                    Text(balance != 0 ? balance.wonFormatted : "-").font(.system(size: 13, weight: .semibold).monospacedDigit()).foregroundStyle(balance >= 0 ? DS.positive : DS.warning).frame(width: 110, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                if idx < rows.count - 1 { Divider().padding(.leading, 16).opacity(0.4) }
            }
        }
    }
    .cardStyle()
}

private func categoryDonut(data: [CategoryData], title: String) -> some View {
    VStack(alignment: .leading, spacing: 14) {
        Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(DS.textPrimary)
        HStack(alignment: .top, spacing: 20) {
            Chart(data) { cd in
                SectorMark(angle: .value("금액", cd.amount), innerRadius: .ratio(0.55), angularInset: 2)
                    .cornerRadius(4).foregroundStyle(by: .value("카테고리", cd.category))
            }
            .chartLegend(.hidden).frame(width: 160, height: 160)

            VStack(spacing: 0) {
                ForEach(data) { cd in
                    HStack(spacing: 8) {
                        Text(CategoryStore.shared.emoji(for: cd.category)).font(.system(size: 14)).frame(width: 22)
                        Text(cd.category).font(.system(size: 13)).foregroundStyle(DS.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        Text(cd.amount.wonFormatted).font(.system(size: 13, weight: .semibold).monospacedDigit()).foregroundStyle(DS.expense)
                        Text("\(Int(cd.percentage))%").font(.system(size: 11)).foregroundStyle(DS.textSecondary).frame(width: 32, alignment: .trailing)
                    }
                    .padding(.vertical, 6)
                    Divider().opacity(0.4)
                }
            }
        }
    }
    .padding(16).cardStyle()
}

// MARK: - Menu label helper

private func menuLabel(_ text: String, isPlaceholder: Bool = false) -> some View {
    HStack(spacing: 6) {
        Text(text)
            .font(.system(size: 13, weight: isPlaceholder ? .regular : .medium))
            .foregroundStyle(isPlaceholder ? DS.textSecondary : DS.textPrimary)
            .lineLimit(1)
        Image(systemName: "chevron.up.chevron.down")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(DS.textSecondary)
    }
    .padding(.horizontal, 12).padding(.vertical, 7)
    .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
    .overlay(RoundedRectangle(cornerRadius: DS.radiusSM).stroke(DS.divider, lineWidth: 0.5))
}

private func shortWon(_ v: Int) -> String {
    if v >= 100_000_000 { return "\(v / 100_000_000)억" }
    if v >= 10_000      { return "\(v / 10_000)만" }
    return "\(v)"
}

// MARK: - Models

struct PeriodData { let label: String; let income: Int; let expense: Int }

private struct FlatBar: Identifiable { let id = UUID(); let label: String; let kind: String; let amount: Int }
private struct CompBar: Identifiable { let id = UUID(); let category: String; let period: String; let amount: Int }

struct CategoryData: Identifiable {
    let id = UUID(); let category: String; let amount: Int; let percentage: Double
    init(category: String, amount: Int, total: Int) {
        self.category = category; self.amount = amount
        self.percentage = total > 0 ? Double(amount) / Double(total) * 100 : 0
    }
}

struct StatMiniCard: View {
    let title: String; let value: Int; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(DS.textSecondary)
            Text(value.wonFormatted).font(.system(size: 15, weight: .bold).monospacedDigit()).foregroundStyle(color).minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14).padding(.vertical, 12).cardStyle()
    }
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        var comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        comps.weekday = 2
        return self.date(from: comps) ?? date
    }
}
