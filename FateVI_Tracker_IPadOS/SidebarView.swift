import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: CombatAppState

    var body: some View {
        List {
            Section("Bereiche") {
                ForEach(AppPanel.allCases) { panel in
                    Button {
                        appState.activePanel = panel
                    } label: {
                        HStack {
                            Label(panel.rawValue, systemImage: icon(for: panel))
                            Spacer()
                            if appState.activePanel == panel {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(Palette.moss)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Sitzung") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(appState.scene.title)
                        .font(.headline)
                    Text("Kampfrunde \(appState.scene.round)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.parchment.opacity(0.9))
    }

    private func icon(for panel: AppPanel) -> String {
        switch panel {
        case .combat: return "square.grid.2x2.fill"
        case .roster: return "person.3.fill"
        case .dice: return "die.face.5.fill"
        case .log: return "text.line.first.and.arrowtriangle.forward"
        }
    }
}
