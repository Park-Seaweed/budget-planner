import Foundation

enum AssetType: String, Codable, CaseIterable {
    case cash       = "cash"
    case bank       = "bank"
    case investment = "investment"
    case realEstate = "realEstate"
    case other      = "other"

    var label: String {
        switch self {
        case .cash:       return "현금"
        case .bank:       return "은행/예금"
        case .investment: return "투자/주식"
        case .realEstate: return "부동산"
        case .other:      return "기타"
        }
    }

    var emoji: String {
        switch self {
        case .cash:       return "💵"
        case .bank:       return "🏦"
        case .investment: return "📈"
        case .realEstate: return "🏠"
        case .other:      return "💼"
        }
    }
}

struct Asset: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var amount: Int
    var type: AssetType
    var memo: String

    init(id: UUID = UUID(), name: String, amount: Int, type: AssetType, memo: String = "") {
        self.id = id
        self.name = name
        self.amount = amount
        self.type = type
        self.memo = memo
    }
}
