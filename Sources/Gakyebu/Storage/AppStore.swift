import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var budgets: [Budget] = []
    @Published var assets: [Asset] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var storage: StorageManager {
        switch StorageSettings.mode {
        case .local:
            return LocalFileStorage()
        case .s3:
            return S3Storage(
                accessKey: StorageSettings.s3AccessKey,
                secretKey: StorageSettings.s3SecretKey,
                bucket:    StorageSettings.s3Bucket,
                region:    StorageSettings.s3Region,
                objectKey: StorageSettings.s3Key
            )
        }
    }

    // MARK: - Load / Save

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await storage.load()
            transactions = data.transactions.sorted { $0.date > $1.date }
            budgets      = data.budgets
            assets       = data.assets
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func save() {
        Task {
            do {
                try await storage.save(AppData(transactions: transactions, budgets: budgets, assets: assets))
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }

    func reload() async { await load() }

    // MARK: - Transactions

    func add(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
        transactions.sort { $0.date > $1.date }
        save()
    }

    func bulkAdd(_ newTransactions: [Transaction]) {
        transactions = (transactions + newTransactions).sorted { $0.date > $1.date }
        save()
    }

    func update(_ transaction: Transaction) {
        if let idx = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[idx] = transaction
            transactions.sort { $0.date > $1.date }
            save()
        }
    }

    func delete(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        save()
    }

    // MARK: - Budgets

    func budget(for category: String, year: Int, month: Int) -> Budget? {
        budgets.first { $0.category == category && $0.year == year && $0.month == month }
    }

    func renameCategory(from oldName: String, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, oldName != trimmed else { return }
        for i in transactions.indices where transactions[i].category == oldName {
            transactions[i].category = trimmed
        }
        for i in budgets.indices where budgets[i].category == oldName {
            budgets[i].category = trimmed
        }
        save()
    }

    func setBudget(category: String, year: Int, month: Int, amount: Int) {
        if let idx = budgets.firstIndex(where: {
            $0.category == category && $0.year == year && $0.month == month
        }) {
            if amount == 0 {
                budgets.remove(at: idx)
            } else {
                budgets[idx].amount = amount
            }
        } else if amount > 0 {
            budgets.append(Budget(year: year, month: month, category: category, amount: amount))
        }
        save()
    }

    // MARK: - Assets

    func addAsset(_ asset: Asset) {
        assets.append(asset)
        save()
    }

    func updateAsset(_ asset: Asset) {
        if let idx = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[idx] = asset
            save()
        }
    }

    func deleteAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        save()
    }

    // MARK: - Helpers

    func transactions(for date: Date) -> [Transaction] {
        let cal = Calendar.current
        let year  = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        return transactions.filter {
            cal.component(.year, from: $0.date) == year &&
            cal.component(.month, from: $0.date) == month
        }
    }

    func totalIncome(for date: Date) -> Int {
        transactions(for: date).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    func totalExpense(for date: Date) -> Int {
        transactions(for: date).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
}
