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

enum CombatCondition: String, CaseIterable, Codable, Identifiable {
    case surprised = "Überrascht"
    case dazed = "Benommen"
    case incapacitated = "Aktionsunfähig"

    var id: String { rawValue }
}

struct WoundTrack: Codable, Hashable {
    var marks: [Bool]

    static let columnCount = 16

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

    init(
        id: UUID = UUID(),
        name: String,
        role: CombatRole,
        initiativeBase: Int,
        specialAbility: String? = nil,
        conditions: Set<CombatCondition> = [],
        woundTrack: WoundTrack = WoundTrack(),
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.initiativeBase = initiativeBase
        self.specialAbility = specialAbility
        self.conditions = conditions
        self.woundTrack = woundTrack
        self.note = note
    }
}

struct InitiativeRoll: Identifiable, Hashable {
    let id = UUID()
    let combatantID: UUID
    let combatantName: String
    let action: CombatActionType
    let initiative: Int
    let isCriticalSuccess: Bool
    let isCriticalFailure: Bool
}

struct CombatSceneSnapshot {
    var title: String
    var round: Int
    var combatants: [Combatant]
    var initiative: [InitiativeRoll]
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
}

extension InitiativeRoll {
    var criticalLabel: String? {
        if isCriticalSuccess { return "Krit. Erfolg" }
        if isCriticalFailure { return "Krit. Fehlschlag" }
        return nil
    }
}
