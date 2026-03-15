import SwiftUI

@main
struct FateVITrackerIPadOSApp: App {
    @StateObject private var appState = CombatAppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
