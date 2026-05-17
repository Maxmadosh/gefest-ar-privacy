import SwiftUI
import Foundation
import Observation

// MARK: - Saved Report Model

struct SavedReport: Identifiable, Codable {
    let id: UUID
    let siteID: String
    let siteName: String
    let date: Date
    let latitude: Double?
    let longitude: Double?
    let photoCount: Int
    let pdfFileName: String
    let specialistName: String
    let companyName: String

    var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: date)
    }

    var coordString: String {
        guard let lat = latitude, let lon = longitude else { return "GPS не определён" }
        return String(format: "%.5f°, %.5f°", lat, lon)
    }

    var pdfURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(pdfFileName)
    }

    var pdfExists: Bool {
        FileManager.default.fileExists(atPath: pdfURL.path)
    }
}

// MARK: - History Manager

@Observable
class HistoryManager {
    static let shared = HistoryManager()

    var reports: [SavedReport] = []

    private let key = "savedReports"

    private init() { load() }

    func save(_ report: SavedReport) {
        reports.insert(report, at: 0)
        persist()
    }

    func delete(_ report: SavedReport) {
        try? FileManager.default.removeItem(at: report.pdfURL)
        reports.removeAll { $0.id == report.id }
        persist()
    }

    func deleteAll() {
        reports.forEach { try? FileManager.default.removeItem(at: $0.pdfURL) }
        reports.removeAll()
        persist()
    }

    var groupedBySite: [(key: String, reports: [SavedReport])] {
        let grouped = Dictionary(grouping: reports) { r in
            r.siteID.isEmpty ? (r.siteName.isEmpty ? "Без названия" : r.siteName) : r.siteID
        }
        return grouped.sorted { $0.key < $1.key }.map { (key: $0.key, reports: $0.value) }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedReport].self, from: data) else { return }
        reports = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(reports) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
