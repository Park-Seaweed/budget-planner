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

            Text(selectedMonth.yearMonth)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
                .frame(minWidth: 120)

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
