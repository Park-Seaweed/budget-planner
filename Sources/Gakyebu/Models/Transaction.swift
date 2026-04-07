import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"

    var label: String {
        switch self {
        case .income: return "수입"
        case .expense: return "지출"
        }
    }
}

struct Transaction: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var amount: Int
    var type: TransactionType
    var category: String
    var title: String
    var memo: String

    init(id: UUID = UUID(), date: Date = .now, amount: Int, type: TransactionType, category: String, title: String = "", memo: String = "") {
        self.id = id
        self.date = date
        self.amount = amount
        self.type = type
        self.category = category
        self.title = title
        self.memo = memo
    }
}
