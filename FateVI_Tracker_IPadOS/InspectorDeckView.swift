import SwiftUI

struct InspectorDeckView: View {
    @EnvironmentObject private var appState: CombatAppState
    @EnvironmentObject private var pixelsService: PixelsBluetoothService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let combatant = appState.selectedCombatant {
                    StageCard(title: combatant.name, subtitle: combatant.role.rawValue) {
                        VStack(alignment: .leading, spacing: 14) {
                            inspectorRow("INI-Basis", "\(combatant.initiativeBase)")
                            inspectorRow("Zustand", combatant.woundSummary)
                            inspectorRow("QM/BEW", "-\(combatant.effectiveQMPenalty) / -\(combatant.effectiveBEWPenalty)")
                            if let lastRoll = combatant.lastRoll {
                                inspectorRow("Letzter Wurf", "\(lastRoll)\(combatant.lastCriticalBonusRoll.map { " + \($0)" } ?? "")")
                            }
                            inspectorRow("Notiz", combatant.note.isEmpty ? "Keine" : combatant.note)
                            if let specialAbility = combatant.specialAbility {
                                inspectorRow("Bes. Vorteil", specialAbility)
                            }
                        }
                    }

                    StageCard(title: "Zustände", subtitle: "Tischschnelle Umschalter für Kernregeln") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(CombatCondition.allCases) { condition in
                                Button {
                                    appState.toggleCondition(condition, for: combatant.id)
                                } label: {
                                    HStack {
                                        Text(condition.rawValue)
                                        Spacer()
                                        Image(systemName: combatant.conditions.contains(condition) ? "checkmark.circle.fill" : "circle")
                                    }
                                    .foregroundStyle(Palette.parchment)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(combatant.conditions.contains(condition) ? Palette.moss.opacity(0.28) : Palette.parchment.opacity(0.06))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    StageCard(title: "Verwundungsmonitor", subtitle: "Klickbar, nicht nur Anzeige") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                            ForEach(Array(combatant.woundTrack.marks.enumerated()), id: \.offset) { index, isMarked in
                                Button {
                                    appState.toggleWoundMark(for: combatant.id, at: index)
                                } label: {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isMarked ? Palette.ember : Palette.parchment.opacity(0.08))
                                        .frame(height: 44)
                                        .overlay(
                                            Text("\(index + 1)")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(Palette.parchment)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    StageCard(title: "Inspektor", subtitle: "Wähle links oder in der Bühne eine Figur aus") {
                        Text("Noch keine Figur ausgewählt.")
                            .foregroundStyle(Palette.mist)
                    }
                }

                StageCard(title: "Pixels-Layer", subtitle: "CoreBluetooth-Schnittstelle vorbereitet") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(pixelsService.status)
                            .foregroundStyle(Palette.mist)
                        Text("Nächster technischer Block: Dice Discovery, Reconnect, Roll-Events und Mapping auf INI-Würfe.")
                            .font(.footnote)
                            .foregroundStyle(Palette.parchment.opacity(0.82))
                        HStack(spacing: 10) {
                            Button("Scan vorbereiten") {
                                pixelsService.startScanning()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Reconnect planen") {
                                pixelsService.reconnectKnownDevices()
                            }
                            .buttonStyle(.bordered)
                        }
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
