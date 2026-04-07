import Foundation

struct Budget: Codable, Identifiable, Equatable {
    var id: UUID
    var year: Int
    var month: Int
    var category: String
    var amount: Int

    init(id: UUID = UUID(), year: Int, month: Int, category: String, amount: Int) {
        self.id = id
        self.year = year
        self.month = month
        self.category = category
        self.amount = amount
    }
}
