import SwiftUI
import CoreLocation
import Observation

// MARK: - App Settings

@Observable
class AppSettings {
    static let shared = AppSettings()

    var companyName: String {
        didSet { UserDefaults.standard.set(companyName, forKey: "companyName") }
    }
    var clientName: String {
        didSet { UserDefaults.standard.set(clientName, forKey: "clientName") }
    }
    var specialistName: String {
        didSet { UserDefaults.standard.set(specialistName, forKey: "specialistName") }
    }
    var specialistRole: String {
        didSet { UserDefaults.standard.set(specialistRole, forKey: "specialistRole") }
    }
    var specialistPhone: String {
        didSet { UserDefaults.standard.set(specialistPhone, forKey: "specialistPhone") }
    }
    var clientRep: String {
        didSet { UserDefaults.standard.set(clientRep, forKey: "clientRep") }
    }
    var isFirstLaunch: Bool {
        didSet { UserDefaults.standard.set(!isFirstLaunch, forKey: "setupCompleted") }
    }

    private init() {
        self.companyName     = UserDefaults.standard.string(forKey: "companyName")     ?? ""
        self.clientName      = UserDefaults.standard.string(forKey: "clientName")      ?? "ООО «НУР Телеком»"
        self.specialistName  = UserDefaults.standard.string(forKey: "specialistName")  ?? ""
        self.specialistRole  = UserDefaults.standard.string(forKey: "specialistRole")  ?? "Инженер-изыскатель"
        self.specialistPhone = UserDefaults.standard.string(forKey: "specialistPhone") ?? ""
        self.clientRep       = UserDefaults.standard.string(forKey: "clientRep")       ?? ""
        self.isFirstLaunch   = !UserDefaults.standard.bool(forKey: "setupCompleted")
    }

    var isConfigured: Bool { !companyName.isEmpty && !specialistName.isEmpty }

    func reset() {
        ["companyName","clientName","specialistName","specialistRole",
         "specialistPhone","clientRep","setupCompleted"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        companyName = ""; clientName = "ООО «НУР Телеком»"
        specialistName = ""; specialistRole = "Инженер-изыскатель"
        specialistPhone = ""; clientRep = ""; isFirstLaunch = true
    }
}

// MARK: - GeoPhoto

struct GeoPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let coordinate: CLLocationCoordinate2D?
    let accuracy: Double?
    let altitude: Double?
    let timestamp: Date

    var hasLocation: Bool { coordinate != nil }

    var latString: String {
        guard let c = coordinate else { return "—" }
        return String(format: "%.6f°", c.latitude)
    }
    var lonString: String {
        guard let c = coordinate else { return "—" }
        return String(format: "%.6f°", c.longitude)
    }
    var coordString: String {
        guard let c = coordinate else { return "GPS недоступен" }
        return String(format: "%.5f°, %.5f°", c.latitude, c.longitude)
    }
    var watermark: String {
        guard let c = coordinate else { return timestamp.formatted() }
        let acc = accuracy.map { String(format: " ±%.0fм", $0) } ?? ""
        return String(format: "%.5f°, %.5f°\(acc)  |  \(timestamp.formatted(date: .abbreviated, time: .shortened))",
                      c.latitude, c.longitude)
    }
    var mapsURL: URL? {
        guard let c = coordinate else { return nil }
        return URL(string: "maps://?q=\(c.latitude),\(c.longitude)&ll=\(c.latitude),\(c.longitude)")
    }
    var yandexMapsURL: URL? {
        guard let c = coordinate else { return nil }
        return URL(string: "yandexmaps://maps.yandex.ru/?pt=\(c.longitude),\(c.latitude)&z=17")
    }
    var googleMapsURL: URL? {
        guard let c = coordinate else { return nil }
        return URL(string: "comgooglemaps://?q=\(c.latitude),\(c.longitude)&zoom=17")
    }
    var timeString: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - Field Trip

@Observable
class FieldTrip {
    var siteID:    String = ""
    var siteName:  String = ""
    var region:    String = ""
    var district:  String = ""
    var address:   String = ""
    var purpose:   TripPurpose = .survey
    var selectedObject: AMOObject?

    var latitude:   Double?
    var longitude:  Double?
    var accuracy:   Double?
    var altitude:   Double?
    var gpsTimestamp: Date?
    var addressResolved: String = ""

    var distances: [DistanceEntry] = []
    var geoPhotos: [GeoPhoto] = []

    var photos: [UIImage] { geoPhotos.map { $0.image } }
    var primaryPhoto: UIImage? { geoPhotos.first?.image }
    var primaryGeoPhoto: GeoPhoto? { geoPhotos.first }

    func addARPhoto(_ image: UIImage, location: CLLocation?) {
        let geo = GeoPhoto(
            image: image,
            coordinate: location?.coordinate,
            accuracy: location?.horizontalAccuracy,
            altitude: location?.altitude,
            timestamp: Date()
        )
        geoPhotos.insert(geo, at: 0)
    }

    let tripDate = Date()

    var docNumber: String {
        let f = DateFormatter(); f.dateFormat = "yyyyMMdd"
        return "ИЗЫ-\(f.string(from: tripDate))-\(Int.random(in: 1000...9999))"
    }
    var dateString: String {
        let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"; return f.string(from: tripDate)
    }
    var gpsTimeString: String {
        guard let ts = gpsTimestamp else { return "—" }
        let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy  HH:mm:ss  (UTC+6)"
        return f.string(from: ts)
    }
    var latString: String {
        guard let lat = latitude else { return "—" }
        return String(format: "%.6f° с.ш.", lat)
    }
    var lonString: String {
        guard let lon = longitude else { return "—" }
        return String(format: "%.6f° в.д.", lon)
    }
    var accuracyString: String {
        guard let acc = accuracy else { return "—" }
        return String(format: "±%.0f м", acc)
    }
    var altitudeString: String {
        guard let alt = altitude else { return "—" }
        return String(format: "%.0f м н.у.м.", alt)
    }
    var isReadyForReport: Bool { !siteID.isEmpty && !siteName.isEmpty && selectedObject != nil }
    var photoWatermark: String {
        var parts: [String] = []
        if !siteID.isEmpty { parts.append(siteID) }
        if let lat = latitude, let lon = longitude {
            parts.append(String(format: "%.5f°, %.5f°", lat, lon))
        }
        parts.append(dateString)
        return parts.joined(separator: "  |  ")
    }
    var mapsURL: URL? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return URL(string: "maps://?q=\(lat),\(lon)&ll=\(lat),\(lon)")
    }
}

// MARK: - Supporting Types

struct DistanceEntry: Identifiable {
    let id = UUID()
    var objectName: String
    var distance: String
    var note: String
}

enum TripPurpose: String, CaseIterable {
    case survey, inspection, mounting, other
    var title: String {
        switch self {
        case .survey: return "Первичные изыскания"
        case .inspection: return "Инспекция сооружения"
        case .mounting: return "Контроль монтажа"
        case .other: return "Иное"
        }
    }
    var icon: String {
        switch self {
        case .survey: return "map"
        case .inspection: return "checklist"
        case .mounting: return "wrench.and.screwdriver"
        case .other: return "ellipsis.circle"
        }
    }
}

extension FieldTrip {
    static let kyrgyzRegions = [
        "Чуйская область", "Таласская область", "Джалал-Абадская область",
        "Ошская область", "Баткенская область", "Нарынская область",
        "Иссык-Кульская область", "г. Бишкек", "г. Ош",
    ]
}
