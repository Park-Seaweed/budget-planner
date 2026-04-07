import Foundation

enum StorageMode: String, Codable, CaseIterable {
    case local = "local"
    case s3    = "s3"

    var label: String {
        switch self {
        case .local: return "로컬 파일"
        case .s3:    return "Amazon S3"
        }
    }
}

struct AppData: Codable {
    var transactions: [Transaction]
    var budgets: [Budget]
    var assets: [Asset]

    init(transactions: [Transaction], budgets: [Budget], assets: [Asset] = []) {
        self.transactions = transactions
        self.budgets = budgets
        self.assets = assets
    }

    static var empty: AppData { AppData(transactions: [], budgets: [], assets: []) }
}

protocol StorageManager: AnyObject {
    func load() async throws -> AppData
    func save(_ data: AppData) async throws
}

// MARK: - Settings persisted in UserDefaults

struct StorageSettings {
    private static let defaults = UserDefaults.standard

    static var mode: StorageMode {
        get { StorageMode(rawValue: defaults.string(forKey: "storageMode") ?? "") ?? .local }
        set { defaults.set(newValue.rawValue, forKey: "storageMode") }
    }

    // S3 credentials  (production: use Keychain)
    static var s3AccessKey: String {
        get { defaults.string(forKey: "s3AccessKey") ?? "" }
        set { defaults.set(newValue, forKey: "s3AccessKey") }
    }
    static var s3SecretKey: String {
        get { defaults.string(forKey: "s3SecretKey") ?? "" }
        set { defaults.set(newValue, forKey: "s3SecretKey") }
    }
    static var s3Bucket: String {
        get { defaults.string(forKey: "s3Bucket") ?? "" }
        set { defaults.set(newValue, forKey: "s3Bucket") }
    }
    static var s3Region: String {
        get { defaults.string(forKey: "s3Region") ?? "ap-northeast-2" }
        set { defaults.set(newValue, forKey: "s3Region") }
    }
    static var s3Key: String {
        get { defaults.string(forKey: "s3Key") ?? "gakyebu/data.json" }
        set { defaults.set(newValue, forKey: "s3Key") }
    }
}
