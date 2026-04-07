import SwiftUI
import Sparkle

@main
struct GakyebuApp: App {
    @StateObject private var store = AppStore()
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task { await store.load() }
        }
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("업데이트 확인...") {
                    updaterController.updater.checkForUpdates()
                }
                .disabled(!updaterController.updater.canCheckForUpdates)
            }
        }
    }
}
