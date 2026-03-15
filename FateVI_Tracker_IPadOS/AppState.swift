import Foundation
import SwiftUI

final class CombatAppState: ObservableObject {
    @Published var activePanel: AppPanel = .combat
    @Published var selectedCombatantID: Combatant.ID?
    @Published var initiativeFilter: InitiativeFilter = .all
    @Published var scene: CombatSceneSnapshot

    private var rules = InitiativeRuleEngine()

    init() {
        let combatants = [
            Combatant(
                name: "Liora Venn",
                role: .pc,
                initiativeBase: 14,
                specialAbility: "Kampfreflexe",
                conditions: [.dazed],
                woundTrack: WoundTrack(marks: [true, true, false, false, false, false, false, true, false, false, false, false, false, false, false, false]),
                note: "Hält die nördliche Flanke."
            ),
            Combatant(
                name: "Iven Marr",
                role: .pc,
                initiativeBase: 11,
                specialAbility: "Schattenlauf",
                conditions: [],
                woundTrack: WoundTrack(),
                note: "Will in Deckung nachziehen."
            ),
            Combatant(
                name: "Torwache A",
                role: .npc,
                initiativeBase: 9,
                conditions: [.surprised],
                woundTrack: WoundTrack(marks: [true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false]),
                note: "Verteidigt den Steg."
            ),
            Combatant(
                name: "Kult-Adept",
                role: .npc,
                initiativeBase: 12,
                specialAbility: "Dunkler Impuls",
                conditions: [],
                woundTrack: WoundTrack(marks: [true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false]),
                note: "Bereitet Fokusaktion vor."
            )
        ]

        let seededScene = CombatSceneSnapshot(
            title: "Ritual am Obsidian-Tor",
            round: 0,
            combatants: combatants,
            initiative: [],
            log: [CombatLogEntry(round: 0, message: "Neue Szene vorbereitet.")]
        )

        self.scene = seededScene
        self.selectedCombatantID = combatants.first?.id
        startNextRound()
    }

    var selectedCombatant: Combatant? {
        scene.combatants.first(where: { $0.id == selectedCombatantID })
    }

    var filteredInitiative: [InitiativeRoll] {
        switch initiativeFilter {
        case .all:
            return scene.initiative
        case .pcs:
            let ids = Set(scene.combatants.filter { $0.role == .pc }.map(\.id))
            return scene.initiative.filter { ids.contains($0.combatantID) }
        case .npcs:
            let ids = Set(scene.combatants.filter { $0.role == .npc }.map(\.id))
            return scene.initiative.filter { ids.contains($0.combatantID) }
        }
    }

    var pcsCount: Int {
        scene.combatants.filter { $0.role == .pc }.count
    }

    var npcsCount: Int {
        scene.combatants.filter { $0.role == .npc }.count
    }

    var readyCombatantsCount: Int {
        scene.combatants.filter { !$0.isIncapacitated }.count
    }

    func selectCombatant(_ combatant: Combatant) {
        selectedCombatantID = combatant.id
    }

    func startNextRound() {
        let nextRound = scene.round + 1
        let resolution = rules.buildNextRound(from: scene.combatants, round: nextRound)
        scene.round = nextRound
        scene.combatants = resolution.combatants
        scene.initiative = resolution.initiative
        scene.log.append(contentsOf: resolution.log)
    }

    func toggleCondition(_ condition: CombatCondition, for combatantID: UUID) {
        guard let index = scene.combatants.firstIndex(where: { $0.id == combatantID }) else { return }
        if scene.combatants[index].conditions.contains(condition) {
            scene.combatants[index].conditions.remove(condition)
        } else {
            scene.combatants[index].conditions.insert(condition)
        }
        let action = scene.combatants[index].conditions.contains(condition) ? "aktiviert" : "deaktiviert"
        scene.log.append(CombatLogEntry(round: scene.round, message: "\(scene.combatants[index].name): \(condition.rawValue) \(action)."))
        scene = scene
    }

    func toggleWoundMark(for combatantID: UUID, at index: Int) {
        guard let combatantIndex = scene.combatants.firstIndex(where: { $0.id == combatantID }) else { return }
        scene.combatants[combatantIndex].woundTrack.toggleMark(at: index)
        let summary = scene.combatants[combatantIndex].woundSummary
        scene.log.append(CombatLogEntry(round: scene.round, message: "\(scene.combatants[combatantIndex].name): Wundmonitor geändert (\(summary))."))
        scene = scene
    }
}
