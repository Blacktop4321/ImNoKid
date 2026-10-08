import Combine
import CoreLocation
import CoreMotion
import Foundation

@MainActor
final class MovementProbe: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?
    @Published private(set) var locationPermission = "Not requested"
    @Published private(set) var motionPermission = "Not requested"
    @Published private(set) var activity = "Waiting for a reading"
    @Published private(set) var confidence = "Unavailable"
    @Published private(set) var locationError: String?

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionActivityManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        updatePermissions()
    }

    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        guard CMMotionActivityManager.isActivityAvailable() else {
            activity = "Unavailable on this device"
            motionPermission = "Unavailable"
            return
        }
        motionManager.startActivityUpdates(to: .main) { [weak self] reading in
            Task { @MainActor in
                guard let self else { return }
                self.updatePermissions()
                guard let reading else { return }
                var labels: [String] = []
                if reading.automotive { labels.append("Driving") }
                if reading.stationary { labels.append("Stationary") }
                if reading.walking { labels.append("Walking") }
                if reading.running { labels.append("Running") }
                if reading.cycling { labels.append("Cycling") }
                if reading.unknown { labels.append("Unknown") }
                self.activity = labels.isEmpty ? "Unclassified" : labels.joined(separator: ", ")
                switch reading.confidence {
                case .low: self.confidence = "Low"
                case .medium: self.confidence = "Medium"
                case .high: self.confidence = "High"
                @unknown default: self.confidence = "Unknown"
                }
            }
        }
        updatePermissions()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        motionManager.stopActivityUpdates()
    }

    func updatePermissions() {
        switch locationManager.authorizationStatus {
        case .notDetermined: locationPermission = "Not requested"
        case .restricted: locationPermission = "Restricted"
        case .denied: locationPermission = "Denied"
        case .authorizedAlways: locationPermission = "Always"
        case .authorizedWhenInUse: locationPermission = "While Using"
        @unknown default: locationPermission = "Unknown"
        }
        switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined: motionPermission = "Not requested"
        case .restricted: motionPermission = "Restricted"
        case .denied: motionPermission = "Denied"
        case .authorized: motionPermission = "Allowed"
        @unknown default: motionPermission = "Unknown"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updatePermissions()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        locationError = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }
}
