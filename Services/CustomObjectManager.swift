import SwiftUI
import Foundation
import Observation

// MARK: - Custom AMO Object

struct CustomAMOObject: Identifiable, Codable {
    let id: String
    var name: String
    var folder: String
    var type: String
    var usdzFileName: String
    var height: String
    var weight: String
    var base: String
    var windLoad: String
    var payload: String
    var material: String
    var description: String
    var colorHex: String

    var isOverride: Bool { id.hasSuffix("_override") }
    var originalID: String { id.replacingOccurrences(of: "_override", with: "") }

    func toAMOObject() -> AMOObject {
        AMOObject(
            id: id, name: name,
            folder: folder.isEmpty ? "Мои объекты" : folder,
            type: type, usdzFileName: usdzFileName,
            height: height, weight: weight, base: base,
            windLoad: windLoad, payload: payload, material: material,
            standard: "—", description: description,
            colorHex: colorHex.isEmpty ? "#FF6B35" : colorHex,
            drawings: []
        )
    }
}

// MARK: - Custom Object Manager

@Observable
class CustomObjectManager {
    static let shared = CustomObjectManager()

    var objects: [CustomAMOObject] = []
    private let key = "customAMOObjects_v2"

    private init() { load() }

    func add(_ obj: CustomAMOObject) {
        objects.insert(obj, at: 0)
        persist()
    }

    func update(_ obj: CustomAMOObject) {
        if let i = objects.firstIndex(where: { $0.id == obj.id }) {
            objects[i] = obj
            persist()
        }
    }

    func delete(_ obj: CustomAMOObject) {
        // Удаляем USDZ только если это НЕ override встроенного
        // (чтобы не удалить файл который используется другим объектом)
        if !obj.isOverride {
            let url = documentsURL.appendingPathComponent(obj.usdzFileName + ".usdz")
            try? FileManager.default.removeItem(at: url)
        }
        objects.removeAll { $0.id == obj.id }
        persist()
    }

    var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func saveUSDZ(from sourceURL: URL, named name: String) -> String? {
        let safeName = name.replacingOccurrences(of: " ", with: "_")
        // Добавляем timestamp чтобы новый файл не конфликтовал со старым
        let uniqueName = safeName + "_\(Int(Date().timeIntervalSince1970))"
        let destURL = documentsURL.appendingPathComponent(uniqueName + ".usdz")
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return uniqueName
        } catch {
            // Попробуем с оригинальным именем
            let dest2 = documentsURL.appendingPathComponent(safeName + ".usdz")
            try? FileManager.default.removeItem(at: dest2)
            try? FileManager.default.copyItem(at: sourceURL, to: dest2)
            return safeName
        }
    }

    // MARK: - Все объекты с применением переопределений

    var allObjects: [AMOObject] {
        // Карта переопределений: originalID → CustomAMOObject
        let overrideMap: [String: CustomAMOObject] = objects
            .filter { $0.isOverride }
            .reduce(into: [:]) { dict, obj in
                dict[obj.originalID] = obj
            }

        // Встроенные с применением override
        let builtIn: [AMOObject] = AMOObject.sampleData.map { obj in
            if let override = overrideMap[obj.id] {
                return override.toAMOObject()
            }
            return obj
        }

        // Пользовательские (не override)
        let custom = objects
            .filter { !$0.isOverride }
            .map { $0.toAMOObject() }

        return builtIn + custom
    }

    // MARK: - Получить объект по ID (с учётом override)

    func object(for id: String) -> AMOObject? {
        allObjects.first { $0.id == id || $0.id == id + "_override" }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([CustomAMOObject].self, from: data) else { return }
        objects = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(objects) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
