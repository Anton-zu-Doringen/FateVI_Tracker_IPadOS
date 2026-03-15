import SwiftUI

struct InspectorDeckView: View {
    @EnvironmentObject private var appState: CombatAppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let combatant = appState.selectedCombatant {
                    StageCard(title: combatant.name, subtitle: combatant.role.rawValue) {
                        VStack(alignment: .leading, spacing: 14) {
                            inspectorRow("INI-Basis", "\(combatant.initiativeBase)")
                            inspectorRow("Zustand", combatant.woundSummary)
                            inspectorRow("Notiz", combatant.note.isEmpty ? "Keine" : combatant.note)
                            if let specialAbility = combatant.specialAbility {
                                inspectorRow("Bes. Vorteil", specialAbility)
                            }
                        }
                    }

                    StageCard(title: "Verwundungsmonitor", subtitle: "iPad-optimierte Schnellansicht") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                            ForEach(Array(combatant.woundTrack.marks.enumerated()), id: \.offset) { index, isMarked in
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isMarked ? Palette.ember : Palette.parchment.opacity(0.08))
                                    .frame(height: 44)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Palette.parchment)
                                    )
                            }
                        }
                    }
                } else {
                    StageCard(title: "Inspektor", subtitle: "Wähle links oder in der Bühne eine Figur aus") {
                        Text("Noch keine Figur ausgewählt.")
                            .foregroundStyle(Palette.mist)
                    }
                }

                StageCard(title: "Pixels-Plan", subtitle: "Native Bluetooth-Anbindung folgt in separatem Layer") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Der iPad-Neubau trennt Regeln, UI und Hardwareintegration. Pixels wird nicht per WebView übernommen, sondern nativ per CoreBluetooth angebunden.")
                            .foregroundStyle(Palette.mist)
                        Text("Nächster technischer Block: Dice Discovery, Reconnect, Roll-Events und Mapping auf INI-Würfe.")
                            .font(.footnote)
                            .foregroundStyle(Palette.parchment.opacity(0.82))
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(Palette.stone.opacity(0.88))
    }

    private func inspectorRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Palette.mist.opacity(0.78))
            Text(value)
                .font(.body)
                .foregroundStyle(Palette.parchment)
        }
    }
}
