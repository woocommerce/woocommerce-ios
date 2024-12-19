import Testing
import CoreLocation
@testable import WooCommerce

struct LocationServiceTests {
    private let sut: LocationService
    private let locationManager: LocationManagerMock

    init() {
        locationManager = LocationManagerMock()
        sut = LocationService(locationManager: locationManager)
    }

    @Test func requestPermission_when_authorizedWhenInUse() {
        // Given
        locationManager.authorizationStatusToReturn = .authorizedWhenInUse

        // When
        sut.requestPermission()

        // Then
        #expect(!locationManager.requestWhenInUseAuthorizationCalled)
    }

    @Test func requestPermission_when_denied() {
        // Given
        locationManager.authorizationStatusToReturn = .denied

        // When
        sut.requestPermission()

        // Then
        #expect(!locationManager.requestWhenInUseAuthorizationCalled)
    }

    @Test func requestPermission_when_notDetermined() {
        // Given
        locationManager.authorizationStatusToReturn = .notDetermined

        // When
        sut.requestPermission()

        // Then
        #expect(locationManager.requestWhenInUseAuthorizationCalled)
    }

    @Test func observePermissionChanges() {
        // Given
        var status: LocationAuthorizationStatus?
        sut.observePermissionChanges {
            status = $0
        }

        // When & Then
        locationManager.changeAuthorizationStatus(to: .restricted)
        #expect(status == .denied)

        locationManager.changeAuthorizationStatus(to: .authorizedAlways)
        #expect(status == .authorized)

        locationManager.changeAuthorizationStatus(to: .notDetermined)
        #expect(status == .notDetermined)
    }

    @Test func stopObservingPermissionChanges() throws {
        // Given
        var status: LocationAuthorizationStatus?
        sut.observePermissionChanges {
            status = $0
        }
        try #require(sut.authorizationStatus == .notDetermined)

        // When
        sut.stopObservingPermissionChanges()
        locationManager.changeAuthorizationStatus(to: .authorizedAlways)

        // Then
        #expect(status == nil)
        #expect(sut.authorizationStatus == .authorized)
    }
}

private class LocationManagerMock: CLLocationManager {
    var authorizationStatusToReturn: CLAuthorizationStatus = .notDetermined
    var requestWhenInUseAuthorizationCalled: Bool = false

    override var authorizationStatus: CLAuthorizationStatus {
        authorizationStatusToReturn
    }

    override func requestWhenInUseAuthorization() {
        requestWhenInUseAuthorizationCalled = true
    }

    func changeAuthorizationStatus(to status: CLAuthorizationStatus) {
        authorizationStatusToReturn = status
        delegate?.locationManagerDidChangeAuthorization?(self)
    }
}
