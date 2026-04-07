import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension Int {
    var wonFormatted: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = ","
        let str = fmt.string(from: NSNumber(value: self)) ?? "\(self)"
        return "₩\(str)"
    }
}

extension Date {
    var yearMonth: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "yyyy년 M월"
        return fmt.string(from: self)
    }

    var shortDate: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일 (E)"
        return fmt.string(from: self)
    }

    func addingMonths(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: n, to: self) ?? self
    }

    func startOfMonth() -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: self)
        return cal.date(from: comps) ?? self
    }

    var year: Int  { Calendar.current.component(.year, from: self) }
    var month: Int { Calendar.current.component(.month, from: self) }
}
