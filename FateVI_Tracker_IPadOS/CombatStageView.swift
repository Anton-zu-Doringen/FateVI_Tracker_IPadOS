import SwiftUI

struct CombatStageView: View {
    @EnvironmentObject private var appState: CombatAppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stageHeader
                rosterStrip
                initiativeDeck
                logDeck
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Nächste KR") {
                    appState.startNextRound()
                }
                .buttonStyle(.borderedProminent)

                Button("Neue Figur") {
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var stageHeader: some View {
        StageCard(title: appState.scene.title, subtitle: "iPad-Kampfbühne mit Fokus auf Lesbarkeit am Tisch") {
            HStack(alignment: .top, spacing: 18) {
                statPill(title: "Kampfrunde", value: "\(appState.scene.round)")
                statPill(title: "SC", value: "\(appState.pcsCount)")
                statPill(title: "NSC", value: "\(appState.npcsCount)")
                statPill(title: "Bereit", value: "\(appState.readyCombatantsCount)")
                Spacer(minLength: 0)
            }
        }
    }

    private var rosterStrip: some View {
        StageCard(title: "Gefechtsgruppen", subtitle: "Schnellzugriff statt klassischer Tabellenansicht") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                ForEach(appState.scene.combatants) { combatant in
                    Button {
                        appState.selectCombatant(combatant)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(combatant.name)
                                    .font(.headline)
                                    .foregroundStyle(Palette.parchment)
                                Spacer()
                                Text(combatant.role.rawValue)
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(combatant.tint.opacity(0.22))
                                    .clipShape(Capsule())
                            }

                            Text(combatant.woundSummary)
                                .font(.subheadline)
                                .foregroundStyle(Palette.mist)

                            if let totalInitiative = combatant.totalInitiative {
                                Text("Aktuelle INI \(totalInitiative)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Palette.parchment.opacity(0.84))
                            }

                            HStack(spacing: 8) {
                                ForEach(Array(combatant.conditions).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { condition in
                                    Text(condition.rawValue)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(Palette.parchment.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(combatant.tint.opacity(appState.selectedCombatantID == combatant.id ? 0.30 : 0.18))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var initiativeDeck: some View {
        StageCard(title: "Initiative-Deck", subtitle: "Aktionen als taktische Timeline statt Browserliste") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    ForEach(InitiativeFilter.allCases) { filter in
                        Button {
                            appState.initiativeFilter = filter
                        } label: {
                            SectionChip(label: filter.rawValue, isActive: appState.initiativeFilter == filter)
                        }
                        .buttonStyle(.plain)
                    }
                }

                ForEach(appState.filteredInitiative) { roll in
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(roll.combatantName)
                                .font(.headline)
                                .foregroundStyle(Palette.parchment)
                            Text(roll.action.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(Palette.mist)
                            Text("3W6 \(roll.rollTotal)\(roll.criticalBonusRoll.map { " + W6 \($0)" } ?? "")\(roll.isSurprised ? " | Überrascht" : "")")
                                .font(.caption)
                                .foregroundStyle(Palette.mist.opacity(0.82))
                        }

                        Spacer()

                        if let critical = roll.criticalLabel {
                            Text(critical)
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background((roll.isCriticalSuccess ? Palette.moss : Palette.ember).opacity(0.28))
                                .clipShape(Capsule())
                        }

                        Text("\(roll.initiative)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.parchment)
                            .frame(minWidth: 62)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Palette.parchment.opacity(0.08))
                    )
                }
            }
        }
    }

    private var logDeck: some View {
        StageCard(title: "Gefechtsprotokoll", subtitle: "Regelereignisse und Rundenauswertung") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(appState.scene.log.suffix(6).reversed())) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("KR \(entry.round)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Palette.sand)
                        Text(entry.message)
                            .font(.footnote)
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
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.mist.opacity(0.85))
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.parchment)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Palette.parchment.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
