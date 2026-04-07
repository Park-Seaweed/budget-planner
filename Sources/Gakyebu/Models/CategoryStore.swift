import Foundation

struct CategoryItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    var type: TransactionType
}

class CategoryStore: ObservableObject {
    static let shared = CategoryStore()

    static let defaultExpenseCategories: [CategoryItem] = [
        CategoryItem(name: "식비",     emoji: "🍽️", type: .expense),
        CategoryItem(name: "교통",     emoji: "🚌", type: .expense),
        CategoryItem(name: "쇼핑",     emoji: "🛍️", type: .expense),
        CategoryItem(name: "문화/여가", emoji: "🎭", type: .expense),
        CategoryItem(name: "의료",     emoji: "💊", type: .expense),
        CategoryItem(name: "통신",     emoji: "📱", type: .expense),
        CategoryItem(name: "주거",     emoji: "🏠", type: .expense),
        CategoryItem(name: "교육",     emoji: "📚", type: .expense),
        CategoryItem(name: "저축",     emoji: "💰", type: .expense),
        CategoryItem(name: "기타",     emoji: "⚙️", type: .expense),
    ]

    static let defaultIncomeCategories: [CategoryItem] = [
        CategoryItem(name: "급여",    emoji: "💼", type: .income),
        CategoryItem(name: "부업",    emoji: "🔧", type: .income),
        CategoryItem(name: "용돈",    emoji: "💝", type: .income),
        CategoryItem(name: "투자수익", emoji: "📈", type: .income),
        CategoryItem(name: "기타수입", emoji: "✨", type: .income),
    ]

    @Published var expenseCategories: [CategoryItem]
    @Published var incomeCategories: [CategoryItem]

    private init() {
        expenseCategories = Self.loadCustom(key: "customExpenseCategories", defaults: Self.defaultExpenseCategories)
        incomeCategories  = Self.loadCustom(key: "customIncomeCategories",  defaults: Self.defaultIncomeCategories)
    }

    func categories(for type: TransactionType) -> [CategoryItem] {
        type == .expense ? expenseCategories : incomeCategories
    }

    func emoji(for category: String) -> String {
        let all = expenseCategories + incomeCategories
        return all.first(where: { $0.name == category })?.emoji ?? "💳"
    }

    func add(name: String, emoji: String, type: TransactionType) {
        let item = CategoryItem(name: name, emoji: emoji, type: type)
        if type == .expense {
            guard !expenseCategories.contains(where: { $0.name == name }) else { return }
            expenseCategories.append(item)
            save(expenseCategories, key: "customExpenseCategories")
        } else {
            guard !incomeCategories.contains(where: { $0.name == name }) else { return }
            incomeCategories.append(item)
            save(incomeCategories, key: "customIncomeCategories")
        }
    }

    func remove(_ item: CategoryItem, type: TransactionType) {
        if type == .expense {
            expenseCategories.removeAll { $0.name == item.name }
            save(expenseCategories, key: "customExpenseCategories")
        } else {
            incomeCategories.removeAll { $0.name == item.name }
            save(incomeCategories, key: "customIncomeCategories")
        }
    }

    func rename(_ item: CategoryItem, newName: String, newEmoji: String, type: TransactionType) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if type == .expense {
            if let idx = expenseCategories.firstIndex(where: { $0.id == item.id }) {
                expenseCategories[idx].name  = trimmed
                expenseCategories[idx].emoji = newEmoji.isEmpty ? item.emoji : newEmoji
            }
            save(expenseCategories, key: "customExpenseCategories")
        } else {
            if let idx = incomeCategories.firstIndex(where: { $0.id == item.id }) {
                incomeCategories[idx].name  = trimmed
                incomeCategories[idx].emoji = newEmoji.isEmpty ? item.emoji : newEmoji
            }
            save(incomeCategories, key: "customIncomeCategories")
        }
    }

    func move(type: TransactionType, from: IndexSet, to: Int) {
        if type == .expense {
            expenseCategories.move(fromOffsets: from, toOffset: to)
            save(expenseCategories, key: "customExpenseCategories")
        } else {
            incomeCategories.move(fromOffsets: from, toOffset: to)
            save(incomeCategories, key: "customIncomeCategories")
        }
    }

    // MARK: - Persistence

    private static func loadCustom(key: String, defaults: [CategoryItem]) -> [CategoryItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([CategoryItem].self, from: data) else {
            return defaults
        }
        return saved
    }

    private func save(_ items: [CategoryItem], key: String) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
