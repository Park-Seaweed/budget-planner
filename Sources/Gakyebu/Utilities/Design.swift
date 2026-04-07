import SwiftUI

enum DS {
    // MARK: - Colors
    static let bg            = Color(hex: "F2F2F7")
    static let card          = Color.white
    static let sidebar       = Color(hex: "EFEFEF")
    static let income        = Color(hex: "2563EB")
    static let expense       = Color(hex: "EF4444")
    static let positive      = Color(hex: "16A34A")
    static let warning       = Color(hex: "F97316")
    static let textPrimary   = Color(hex: "0A0A0A")
    static let textSecondary = Color(hex: "3D3D3D")
    static let divider       = Color(hex: "E5E7EB")
    static let accent        = Color(hex: "2563EB")

    // MARK: - Radius
    static let radiusSM: CGFloat = 8
    static let radius:   CGFloat = 12
    static let radiusLG: CGFloat = 16
}

// MARK: - Card style (no shadow)

struct CardStyle: ViewModifier {
    var radius: CGFloat = DS.radius
    func body(content: Content) -> some View {
        content
            .background(DS.card, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(DS.divider, lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle(radius: CGFloat = DS.radius) -> some View {
        modifier(CardStyle(radius: radius))
    }
}

// MARK: - Placeholder TextField

struct PlaceholderTextField: View {
    let placeholder: String
    @Binding var text: String
    var font: Font = .system(size: 14)

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .foregroundStyle(Color(hex: "ABABAB"))
                    .allowsHitTesting(false)
            }
            TextField("", text: $text)
                .font(font)
                .textFieldStyle(.plain)
                .foregroundStyle(DS.textPrimary)
        }
    }
}

// MARK: - Month Navigator

struct MonthNavigator: View {
    @Binding var selectedMonth: Date
    var limitToday: Bool = true
    @State private var showPicker = false

    private var currentYear: Int { Calendar.current.component(.year, from: selectedMonth) }
    private var currentMonthNum: Int { Calendar.current.component(.month, from: selectedMonth) }

    var body: some View {
        HStack(spacing: 20) {
            Button {
                selectedMonth = selectedMonth.addingMonths(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(DS.card, in: Circle())
                    .overlay(Circle().stroke(DS.divider, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Button {
                showPicker = true
            } label: {
                Text(selectedMonth.yearMonth)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .frame(minWidth: 120)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                YearMonthPickerView(selectedMonth: $selectedMonth, limitToday: limitToday)
                    .padding(16)
                    .frame(width: 280)
            }

            Button {
                selectedMonth = selectedMonth.addingMonths(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(limitToday && selectedMonth >= Date().startOfMonth()
                                     ? DS.textSecondary : DS.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(DS.card, in: Circle())
                    .overlay(Circle().stroke(DS.divider, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(limitToday && selectedMonth >= Date().startOfMonth())
        }
    }
}

// MARK: - Year/Month Picker Popover

struct YearMonthPickerView: View {
    @Binding var selectedMonth: Date
    var limitToday: Bool
    @Environment(\.dismiss) private var dismiss

    private let cal = Calendar.current
    private var selectedYear: Int { cal.component(.year, from: selectedMonth) }
    private var selectedMonthNum: Int { cal.component(.month, from: selectedMonth) }
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let currentMonthNum = Calendar.current.component(.month, from: Date())
    private let years: [Int] = Array((2000...Calendar.current.component(.year, from: Date())).reversed())
    private let monthNames = ["1월","2월","3월","4월","5월","6월","7월","8월","9월","10월","11월","12월"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("연도 선택")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DS.textSecondary)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(years, id: \.self) { y in
                            let isSelected = y == selectedYear
                            Button {
                                setYear(y)
                            } label: {
                                Text(String(y))
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? .white : DS.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? DS.accent : DS.bg, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .id(y)
                        }
                    }
                }
                .onAppear { proxy.scrollTo(selectedYear, anchor: .center) }
            }

            Divider().opacity(0.4)

            Text("월 선택")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DS.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                ForEach(1...12, id: \.self) { m in
                    let isSelected = m == selectedMonthNum
                    let isDisabled = limitToday && selectedYear == currentYear && m > currentMonthNum
                    Button {
                        setMonth(m)
                        dismiss()
                    } label: {
                        Text(monthNames[m - 1])
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isDisabled ? DS.textSecondary.opacity(0.4) : isSelected ? .white : DS.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(isSelected ? DS.accent : DS.bg, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                }
            }
        }
    }

    private func setYear(_ y: Int) {
        var m = selectedMonthNum
        if limitToday && y == currentYear && m > currentMonthNum { m = currentMonthNum }
        var comps = DateComponents(); comps.year = y; comps.month = m; comps.day = 1
        if let d = cal.date(from: comps) { selectedMonth = d }
    }

    private func setMonth(_ m: Int) {
        var comps = DateComponents(); comps.year = selectedYear; comps.month = m; comps.day = 1
        if let d = cal.date(from: comps) { selectedMonth = d }
    }
}
