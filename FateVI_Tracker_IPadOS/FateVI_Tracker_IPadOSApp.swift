import SwiftUI

@main
struct FateVITrackerIPadOSApp: App {
    @StateObject private var appState = CombatAppState()
    @StateObject private var pixelsService = PixelsBluetoothService()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(pixelsService)
        }
    }
}
