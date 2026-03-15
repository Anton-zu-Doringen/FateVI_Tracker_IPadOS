import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: CombatAppState
    @EnvironmentObject private var pixelsService: PixelsBluetoothService

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 260, ideal: 290)
        } content: {
            contentView
                .navigationSplitViewColumnWidth(min: 620, ideal: 760)
        } detail: {
            detailView
                .navigationSplitViewColumnWidth(min: 320, ideal: 360)
        }
        .background(StageBackground())
    }

    @ViewBuilder
    private var contentView: some View {
        switch appState.activePanel {
        case .combat:
            CombatStageView()
        case .roster:
            ScrollView {
                StageCard(title: "Roster-Deck", subtitle: "Dedizierte Verwaltungsfläche für Gruppen und NSC-Pakete") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                        ForEach(appState.scene.combatants) { combatant in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(combatant.name)
                                    .font(.headline)
                                    .foregroundStyle(Palette.parchment)
                                Text("\(combatant.role.rawValue) | INI \(combatant.initiativeBase)")
                                    .foregroundStyle(Palette.mist)
                                Text(combatant.note.isEmpty ? "Keine Notiz" : combatant.note)
                                    .font(.footnote)
                                    .foregroundStyle(Palette.parchment.opacity(0.82))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(combatant.tint.opacity(0.18))
                            )
                        }
                    }
                }
                .padding(24)
            }
        case .dice:
            ScrollView {
                StageCard(title: "Pixels Bridge", subtitle: "Native iPadOS-Integration statt Browser-WebBluetooth") {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(pixelsService.status)
                            .foregroundStyle(Palette.mist)
                        Text("Diese Fläche wird zum nativen Dice-Hub für Discovery, Reconnect, Zuordnung und Rollfluss.")
                            .foregroundStyle(Palette.parchment)
                    }
                }
                .padding(24)
            }
        case .log:
            ScrollView {
                StageCard(title: "Kampfprotokoll", subtitle: "Volle Chronik der Sitzung") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(appState.scene.log.reversed())) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("KR \(entry.round)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Palette.sand)
                                Text(entry.message)
                                    .foregroundStyle(Palette.parchment)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Palette.parchment.opacity(0.06))
                            )
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.activePanel {
        case .combat, .roster:
            InspectorDeckView()
        case .dice:
            ScrollView {
                StageCard(title: "Integrationspfad", subtitle: "Technischer Plan für die Bluetooth-Schicht") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. BLE-Discovery und Berechtigungen")
                        Text("2. Persistente Gerätezuordnung")
                        Text("3. Roll-Events und D6-Auswertung")
                        Text("4. LED- und Reconnect-Strategie")
                    }
                    .foregroundStyle(Palette.parchment)
                }
                .padding(20)
            }
            .background(Palette.stone.opacity(0.88))
        case .log:
            ScrollView {
                StageCard(title: "Regelstatus", subtitle: "Aktuelle Kernmechanik im nativen Rewrite") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Initiative: 3W6 + INI, Überrascht -10, Krit-Erfolg +W6, Bonusaktion über 30.")
                        Text("Verwundungen: rechter Marker bestimmt QM/BEW-Abzug.")
                        Text("Benommen: zusätzlicher QM-Malus von 3.")
                    }
                    .foregroundStyle(Palette.parchment)
                }
                .padding(20)
            }
            .background(Palette.stone.opacity(0.88))
        }
    }
}
