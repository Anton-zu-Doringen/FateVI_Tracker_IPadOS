import Foundation
import SwiftUI

final class CombatAppState: ObservableObject {
    @Published var activePanel: AppPanel = .combat
    @Published var selectedCombatantID: Combatant.ID?
    @Published var initiativeFilter: InitiativeFilter = .all
    @Published var scene: CombatSceneSnapshot = CombatSceneSnapshot(
        title: "Ritual am Obsidian-Tor",
        round: 3,
        combatants: [
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
                specialAbility: nil,
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
        ],
        initiative: [
            InitiativeRoll(combatantID: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(), combatantName: "Liora Venn", action: .bonus, initiative: 31, isCriticalSuccess: true, isCriticalFailure: false),
            InitiativeRoll(combatantID: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(), combatantName: "Liora Venn", action: .main, initiative: 31, isCriticalSuccess: true, isCriticalFailure: false),
            InitiativeRoll(combatantID: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(), combatantName: "Iven Marr", action: .main, initiative: 18, isCriticalSuccess: false, isCriticalFailure: false),
            InitiativeRoll(combatantID: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(), combatantName: "Kult-Adept", action: .main, initiative: 16, isCriticalSuccess: false, isCriticalFailure: false),
            InitiativeRoll(combatantID: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(), combatantName: "Torwache A", action: .move, initiative: 9, isCriticalSuccess: false, isCriticalFailure: true)
        ]
    )

    init() {
        if let firstCombatant = scene.combatants.first {
            selectedCombatantID = firstCombatant.id
        }
        remapSampleInitiativeToCombatants()
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

    func selectCombatant(_ combatant: Combatant) {
        selectedCombatantID = combatant.id
    }

    func advanceRoundPreview() {
        scene.round += 1
    }

    private func remapSampleInitiativeToCombatants() {
        let idsByName = Dictionary(uniqueKeysWithValues: scene.combatants.map { ($0.name, $0.id) })
        scene.initiative = scene.initiative.map { roll in
            InitiativeRoll(
                combatantID: idsByName[roll.combatantName] ?? roll.combatantID,
                combatantName: roll.combatantName,
                action: roll.action,
                initiative: roll.initiative,
                isCriticalSuccess: roll.isCriticalSuccess,
                isCriticalFailure: roll.isCriticalFailure
            )
        }
    }
}
