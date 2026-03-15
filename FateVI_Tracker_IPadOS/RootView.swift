import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: CombatAppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 260, ideal: 290)
        } content: {
            CombatStageView()
                .navigationSplitViewColumnWidth(min: 620, ideal: 760)
        } detail: {
            InspectorDeckView()
                .navigationSplitViewColumnWidth(min: 320, ideal: 360)
        }
        .background(StageBackground())
    }
}
