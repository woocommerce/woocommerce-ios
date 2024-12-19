import Foundation
import CoreLocation

protocol LocationServiceProtocol {
    func requestPermission()
    func observePermissionChanges(_ onChange: @escaping (LocationAuthorizationStatus) -> Void)
    func stopObservingPermissionChanges()
    var authorizationStatus: LocationAuthorizationStatus { get }
}

enum LocationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
}

final class LocationService: NSObject, LocationServiceProtocol {
    private let locationManager: CLLocationManager
    private var onStatusChange: ((LocationAuthorizationStatus) -> Void)?

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        locationManager.delegate = self
    }

    func requestPermission() {
        let status = locationManager.authorizationStatus

        guard status == .notDetermined else {
            return
        }

        locationManager.requestWhenInUseAuthorization()
    }

    func observePermissionChanges(_ onChange: @escaping (LocationAuthorizationStatus) -> Void) {
        onStatusChange = onChange
    }

    func stopObservingPermissionChanges() {
        onStatusChange = nil
    }

    var authorizationStatus: LocationAuthorizationStatus {
        let status = locationManager.authorizationStatus
        return authorizationStatus(from: status)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onStatusChange?(authorizationStatus(from: manager.authorizationStatus))
    }
}

// MARK: - Mapping Status

private extension LocationService {
    func authorizationStatus(from status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .restricted, .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
}
