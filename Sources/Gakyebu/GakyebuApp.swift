import SwiftUI
import Sparkle

final class UpdaterViewModel: ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var canCheckForUpdates: Bool { updaterController.updater.canCheckForUpdates }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}

@main
struct GakyebuApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var updater = UpdaterViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(updater)
                .task { await store.load() }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        updater.checkForUpdates()
                    }
                }
        }
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("업데이트 확인...") {
                    updater.checkForUpdates()
                }
                .disabled(!updater.canCheckForUpdates)
            }
        }
    }
}
