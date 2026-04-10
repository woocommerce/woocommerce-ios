import Combine
@testable import WooCommerce
import WooFoundation

final class MockConnectivityObserver: ConnectivityObserver {
    @Published private(set) var currentStatus: ConnectivityStatus = .unknown

    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> {
        $currentStatus.eraseToAnyPublisher()
    }

    func setStatus(_ status: ConnectivityStatus) {
        currentStatus = status
    }
}
