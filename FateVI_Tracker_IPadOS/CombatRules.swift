import Foundation

enum InitiativeSourceMode {
    case automatic
    case manualOverride
}

struct InitiativeRuleEngine {
    var rng: RandomNumberGenerator

    init(rng: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.rng = rng
    }

    mutating func buildNextRound(
        from combatants: [Combatant],
        round: Int
    ) -> (combatants: [Combatant], initiative: [InitiativeRoll], log: [CombatLogEntry]) {
        var updatedCombatants: [Combatant] = []
        var entries: [InitiativeRoll] = []
        var logs: [CombatLogEntry] = []

        for combatant in combatants {
            if combatant.isIncapacitated {
                var skipped = combatant
                skipped.lastRoll = nil
                skipped.lastCriticalBonusRoll = nil
                skipped.totalInitiative = nil
                updatedCombatants.append(skipped)
                logs.append(CombatLogEntry(round: round, message: "\(combatant.name) ist aktionsunfähig und wird in dieser KR übersprungen."))
                continue
            }

            let resolution = resolveInitiative(for: combatant)
            var updated = combatant
            updated.lastRoll = resolution.rollTotal
            updated.lastCriticalBonusRoll = resolution.criticalBonusRoll
            updated.totalInitiative = resolution.totalInitiative
            updatedCombatants.append(updated)

            for (index, action) in resolution.actions.enumerated() {
                entries.append(
                    InitiativeRoll(
                        id: UUID(),
                        combatantID: combatant.id,
                        combatantName: combatant.name,
                        action: action,
                        initiative: resolution.totalInitiative,
                        groupInitiative: resolution.totalInitiative,
                        isCriticalSuccess: resolution.isCriticalSuccess,
                        isCriticalFailure: resolution.isCriticalFailure,
                        rollTotal: resolution.rollTotal,
                        criticalBonusRoll: resolution.criticalBonusRoll,
                        isSurprised: resolution.isSurprised
                    )
                )
                if index == 0 {
                    logs.append(
                        CombatLogEntry(
                            round: round,
                            message: logMessage(for: combatant, resolution: resolution)
                        )
                    )
                }
            }
        }

        entries.sort { lhs, rhs in
            if lhs.groupInitiative != rhs.groupInitiative {
                return lhs.groupInitiative > rhs.groupInitiative
            }
            if lhs.combatantName != rhs.combatantName {
                return lhs.combatantName.localizedCompare(rhs.combatantName) == .orderedAscending
            }
            return actionRank(lhs.action) < actionRank(rhs.action)
        }

        return (updatedCombatants, entries, logs)
    }

    mutating func resolveInitiative(for combatant: Combatant) -> InitiativeResolution {
        let rollTotal = combatant.manualRollOverride ?? roll3d6()
        let isCriticalSuccess = rollTotal == 18
        let isCriticalFailure = rollTotal == 3
        let criticalBonusRoll = isCriticalSuccess ? d6() : nil
        let surprisedPenalty = combatant.isSurprised ? 10 : 0
        let totalInitiative = combatant.initiativeBase + rollTotal + (criticalBonusRoll ?? 0) - surprisedPenalty
        var actions: [CombatActionType] = [.main, .move]
        if totalInitiative > 30 {
            actions.insert(.bonus, at: 0)
        }

        return InitiativeResolution(
            combatantID: combatant.id,
            rollTotal: rollTotal,
            criticalBonusRoll: criticalBonusRoll,
            totalInitiative: totalInitiative,
            isCriticalSuccess: isCriticalSuccess,
            isCriticalFailure: isCriticalFailure,
            isSurprised: combatant.isSurprised,
            actions: actions
        )
    }

    private mutating func roll3d6() -> Int {
        d6() + d6() + d6()
    }

    private mutating func d6() -> Int {
        Int.random(in: 1...6, using: &rng)
    }

    private func actionRank(_ action: CombatActionType) -> Int {
        switch action {
        case .bonus: return 0
        case .main: return 1
        case .move: return 2
        }
    }

    private func logMessage(for combatant: Combatant, resolution: InitiativeResolution) -> String {
        var parts: [String] = ["\(combatant.name): 3W6 \(resolution.rollTotal)"]
        if let criticalBonusRoll = resolution.criticalBonusRoll {
            parts.append("Krit-W6 \(criticalBonusRoll)")
        }
        parts.append("ges. INI \(resolution.totalInitiative)")
        if resolution.isSurprised {
            parts.append("Überrascht -10")
        }
        if resolution.isCriticalSuccess {
            parts.append("kritischer Erfolg")
        } else if resolution.isCriticalFailure {
            parts.append("kritischer Fehlschlag")
        }
        if resolution.actions.contains(.bonus) {
            parts.append("Bonusaktion")
        }
        return parts.joined(separator: " | ")
    }
}
