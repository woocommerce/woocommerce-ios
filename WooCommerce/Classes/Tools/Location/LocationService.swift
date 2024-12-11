import Foundation
import CoreLocation

protocol LocationServiceProtocol {
    func requestPermission(_ completion: @escaping (LocationAuthorizationStatus) -> Void)
    func observePermissionChanges(_ onChange: @escaping (LocationAuthorizationStatus) -> Void)
    var authorizationStatus: LocationAuthorizationStatus { get }
}

enum LocationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
}

final class LocationService: NSObject, LocationServiceProtocol {
    private let locationManager = CLLocationManager()
    private var permissionCompletion: ((LocationAuthorizationStatus) -> Void)?
    private var onStatusChange: ((LocationAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestPermission(_ completion: @escaping (LocationAuthorizationStatus) -> Void) {
        permissionCompletion = completion

        let status = locationManager.authorizationStatus

        guard status == .notDetermined else {
            return completion(authorizationStatus(from: status))
        }

        locationManager.requestWhenInUseAuthorization()
    }

    func observePermissionChanges(_ onChange: @escaping (LocationAuthorizationStatus) -> Void) {
        onStatusChange = onChange
    }

    var authorizationStatus: LocationAuthorizationStatus {
        let status = locationManager.authorizationStatus
        return authorizationStatus(from: status)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if let completion = permissionCompletion {
            completion(authorizationStatus(from: status))
            permissionCompletion = nil
        }

        if let onChange = onStatusChange {
            onChange(authorizationStatus(from: status))
        }
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
