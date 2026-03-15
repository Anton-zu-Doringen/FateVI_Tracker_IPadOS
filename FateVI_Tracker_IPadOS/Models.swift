import Foundation
import SwiftUI

enum CombatRole: String, CaseIterable, Codable, Identifiable {
    case pc = "SC"
    case npc = "NSC"

    var id: String { rawValue }
}

enum CombatActionType: String, CaseIterable, Codable, Identifiable {
    case bonus = "Bonus"
    case main = "Haupt"
    case move = "Bewegung"

    var id: String { rawValue }
}

enum CombatCondition: String, CaseIterable, Codable, Identifiable, Hashable {
    case surprised = "Überrascht"
    case dazed = "Benommen"
    case incapacitated = "Aktionsunfähig"

    var id: String { rawValue }
}

struct WoundPenalty: Hashable {
    let qm: Int
    let bew: Int
}

struct WoundTrack: Codable, Hashable {
    static let columnCount = 16
    static let qmValues = [0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 7, 8, 9, 12, 15]
    static let bewValues = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 5, 7]

    var marks: [Bool]

    init(marks: [Bool] = Array(repeating: false, count: WoundTrack.columnCount)) {
        var normalized = Array(repeating: false, count: WoundTrack.columnCount)
        for index in 0..<min(marks.count, WoundTrack.columnCount) {
            normalized[index] = marks[index]
        }
        self.marks = normalized
    }

    var highestMarkedIndex: Int? {
        marks.lastIndex(where: { $0 })
    }

    var penalty: WoundPenalty {
        guard let highestMarkedIndex else {
            return WoundPenalty(qm: 0, bew: 0)
        }
        return WoundPenalty(
            qm: WoundTrack.qmValues[highestMarkedIndex],
            bew: WoundTrack.bewValues[highestMarkedIndex]
        )
    }

    mutating func toggleMark(at index: Int) {
        guard marks.indices.contains(index) else { return }
        marks[index].toggle()
    }
}

struct Combatant: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var role: CombatRole
    var initiativeBase: Int
    var specialAbility: String?
    var conditions: Set<CombatCondition>
    var woundTrack: WoundTrack
    var note: String
    var manualRollOverride: Int?
    var lastRoll: Int?
    var lastCriticalBonusRoll: Int?
    var totalInitiative: Int?

    init(
        id: UUID = UUID(),
        name: String,
        role: CombatRole,
        initiativeBase: Int,
        specialAbility: String? = nil,
        conditions: Set<CombatCondition> = [],
        woundTrack: WoundTrack = WoundTrack(),
        note: String = "",
        manualRollOverride: Int? = nil,
        lastRoll: Int? = nil,
        lastCriticalBonusRoll: Int? = nil,
        totalInitiative: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.initiativeBase = initiativeBase
        self.specialAbility = specialAbility
        self.conditions = conditions
        self.woundTrack = woundTrack
        self.note = note
        self.manualRollOverride = manualRollOverride
        self.lastRoll = lastRoll
        self.lastCriticalBonusRoll = lastCriticalBonusRoll
        self.totalInitiative = totalInitiative
    }
}

struct InitiativeRoll: Identifiable, Hashable {
    let id: UUID
    let combatantID: UUID
    let combatantName: String
    let action: CombatActionType
    let initiative: Int
    let groupInitiative: Int
    let isCriticalSuccess: Bool
    let isCriticalFailure: Bool
    let rollTotal: Int
    let criticalBonusRoll: Int?
    let isSurprised: Bool
}

struct InitiativeResolution: Hashable {
    let combatantID: UUID
    let rollTotal: Int
    let criticalBonusRoll: Int?
    let totalInitiative: Int
    let isCriticalSuccess: Bool
    let isCriticalFailure: Bool
    let isSurprised: Bool
    let actions: [CombatActionType]
}

struct CombatLogEntry: Identifiable, Hashable {
    let id: UUID
    let round: Int
    let timestamp: Date
    let message: String

    init(id: UUID = UUID(), round: Int, timestamp: Date = Date(), message: String) {
        self.id = id
        self.round = round
        self.timestamp = timestamp
        self.message = message
    }
}

struct CombatSceneSnapshot {
    var title: String
    var round: Int
    var combatants: [Combatant]
    var initiative: [InitiativeRoll]
    var log: [CombatLogEntry]
}

enum AppPanel: String, CaseIterable, Identifiable {
    case combat = "Gefecht"
    case roster = "Roster"
    case dice = "Pixels"
    case log = "Protokoll"

    var id: String { rawValue }
}

enum InitiativeFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case pcs = "SC"
    case npcs = "NSC"

    var id: String { rawValue }
}

extension Combatant {
    var woundSummary: String {
        guard let index = woundTrack.highestMarkedIndex else {
            return "Unverletzt"
        }
        switch index {
        case 0...4:
            return "Kratzer"
        case 5...9:
            return "Verwundet"
        case 10...13:
            return "Schwer verwundet"
        default:
            return "Kritisch"
        }
    }

    var tint: Color {
        role == .pc ? Palette.moss : Palette.copper
    }

    var isIncapacitated: Bool {
        conditions.contains(.incapacitated)
    }

    var isSurprised: Bool {
        conditions.contains(.surprised)
    }

    var isDazed: Bool {
        conditions.contains(.dazed)
    }

    var effectiveQMPenalty: Int {
        woundTrack.penalty.qm + (isDazed ? 3 : 0)
    }

    var effectiveBEWPenalty: Int {
        woundTrack.penalty.bew
    }
}

extension InitiativeRoll {
    var criticalLabel: String? {
        if isCriticalSuccess { return "Krit. Erfolg" }
        if isCriticalFailure { return "Krit. Fehlschlag" }
        return nil
    }
}
