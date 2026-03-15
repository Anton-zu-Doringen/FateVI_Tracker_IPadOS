import Foundation
import SwiftUI

struct SavedCombatScene: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var savedAt: Date
    var snapshot: CombatSceneSnapshot
}

@MainActor
final class CombatPersistenceController: ObservableObject {
    @Published private(set) var savedScenes: [SavedCombatScene] = []
    @Published private(set) var status: String = "Noch keine Kämpfe lokal gespeichert."

    private let storeURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        storeURL = documentsURL.appendingPathComponent("saved-combats.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        loadSavedScenes()
    }

    func loadSavedScenes() {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            savedScenes = []
            status = "Noch keine Kämpfe lokal gespeichert."
            return
        }

        do {
            let data = try Data(contentsOf: storeURL)
            savedScenes = try decoder.decode([SavedCombatScene].self, from: data)
                .sorted { $0.savedAt > $1.savedAt }
            status = "\(savedScenes.count) Kampfstände lokal geladen."
        } catch {
            savedScenes = []
            status = "Lokaler Kampfspeicher konnte nicht gelesen werden: \(error.localizedDescription)"
        }
    }

    func save(scene: CombatSceneSnapshot, named name: String? = nil) {
        let trimmedName = (name ?? scene.title).trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = SavedCombatScene(
            id: UUID(),
            name: trimmedName.isEmpty ? "Unbenannter Kampf" : trimmedName,
            savedAt: Date(),
            snapshot: scene
        )
        savedScenes.insert(entry, at: 0)
        writeStore(statusMessage: "Kampf \"\(entry.name)\" lokal gespeichert.")
    }

    func overwriteMostRecent(scene: CombatSceneSnapshot) {
        guard !savedScenes.isEmpty else {
            save(scene: scene)
            return
        }
        savedScenes[0].savedAt = Date()
        savedScenes[0].snapshot = scene
        writeStore(statusMessage: "Aktuellster Kampfstand aktualisiert.")
    }

    func delete(sceneID: UUID) {
        savedScenes.removeAll { $0.id == sceneID }
        writeStore(statusMessage: savedScenes.isEmpty ? "Alle lokalen Kampfstände entfernt." : "Kampfstand gelöscht.")
    }

    func restore(sceneID: UUID) -> CombatSceneSnapshot? {
        guard let entry = savedScenes.first(where: { $0.id == sceneID }) else {
            status = "Gewählter Kampfstand nicht gefunden."
            return nil
        }
        status = "Kampf \"\(entry.name)\" geladen."
        return entry.snapshot
    }

    private func writeStore(statusMessage: String) {
        do {
            let data = try encoder.encode(savedScenes.sorted { $0.savedAt > $1.savedAt })
            try data.write(to: storeURL, options: [.atomic])
            status = statusMessage
        } catch {
            status = "Lokaler Kampfspeicher konnte nicht geschrieben werden: \(error.localizedDescription)"
        }
    }
}
