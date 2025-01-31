import Foundation
@testable import WooCommerce

final class MockLocationService: LocationServiceProtocol {
    private var observers: [(LocationAuthorizationStatus) -> Void] = []
    private var currentStatus: LocationAuthorizationStatus
    var requestPermissionStatus: LocationAuthorizationStatus = .notDetermined

    init(status: LocationAuthorizationStatus = .authorized) {
        self.currentStatus = status
    }

    var authorizationStatus: LocationAuthorizationStatus {
        currentStatus
    }

    func requestPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.currentStatus = self.requestPermissionStatus
            self.notifyObservers()
        }
    }

    func observePermissionChanges(_ onChange: @escaping (LocationAuthorizationStatus) -> Void) {
        observers.append(onChange)
    }

    func stopObservingPermissionChanges() {
        observers.removeAll()
    }

    func simulatePermissionChange(to newStatus: LocationAuthorizationStatus) {
        currentStatus = newStatus
        notifyObservers()
    }

    private func notifyObservers() {
        for observer in observers {
            observer(currentStatus)
        }
    }
}
