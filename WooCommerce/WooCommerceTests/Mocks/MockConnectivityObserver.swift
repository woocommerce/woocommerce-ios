import Combine
@testable import WooCommerce

final class MockConnectivityObserver: ConnectivityObserver {
    @Published private(set) var currentStatus: ConnectivityStatus = .unknown

    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> {
        $currentStatus.eraseToAnyPublisher()
    }

    func startObserving() {
        // no-op
    }

    func stopObserving() {
        // no-op
    }

    func setStatus(_ status: ConnectivityStatus) {
        currentStatus = status
    }
}
