import CoreLocation
import SwiftUI
import Observation

// MARK: - Location Manager

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var location: CLLocation?
    var address: String = "Определение адреса..."
    var authStatus: CLAuthorizationStatus = .notDetermined
    var isAuthorized: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        checkAuthorization()
    }

    func checkAuthorization() {
        authStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            break
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Delegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last,
              loc.horizontalAccuracy >= 0,
              loc.horizontalAccuracy < 100 else { return }
        DispatchQueue.main.async {
            self.location = loc
            self.reverseGeocode(loc)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isAuthorized = true
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.isAuthorized = false
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Error: \(error.localizedDescription)")
    }

    func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let placemark = placemarks?.first else { return }
            let parts = [
                placemark.country,
                placemark.administrativeArea,
                placemark.locality,
                placemark.thoroughfare,
                placemark.subThoroughfare
            ].compactMap { $0 }
            DispatchQueue.main.async {
                self?.address = parts.joined(separator: ", ")
            }
        }
    }

    // MARK: - Computed

    var coordinateString: String {
        guard let loc = location else { return "GPS недоступен" }
        return String(format: "%.6f°, %.6f°", loc.coordinate.latitude, loc.coordinate.longitude)
    }

    var accuracyString: String {
        guard let loc = location else { return "—" }
        return String(format: "±%.0f м", loc.horizontalAccuracy)
    }

    var mapsURL: URL? {
        guard let loc = location else { return nil }
        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        return URL(string: "maps://?q=\(lat),\(lon)&ll=\(lat),\(lon)")
    }
}
