import Network
import XCTest
@testable import WooCommerce

final class DefaultConnectivityObserverTests: XCTestCase {
    func test_initializing_observer_triggers_network_monitoring() {
        // Given
        let network = MockNetwork(status: .satisfied, currentInterface: .wifi)
        let networkMonitor = MockNetworkMonitor(currentNetwork: network)

        // When
        let _ = DefaultConnectivityObserver(networkMonitor: networkMonitor)

        // Then
        XCTAssertTrue(networkMonitor.didStartMonitoring)
    }

    func test_stopping_observer_stops_network_monitoring() {
        // Given
        let network = MockNetwork(status: .satisfied, currentInterface: .wifi)
        let networkMonitor = MockNetworkMonitor(currentNetwork: network)

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        observer.stopObserving()

        // Then
        XCTAssertTrue(networkMonitor.didStopMonitoring)
    }

    func test_currentStatus_returns_correctly_when_network_is_satisfied() {
        // Given
        let network = MockNetwork(status: .satisfied, currentInterface: .wifi)
        let networkMonitor = MockNetworkMonitor(currentNetwork: network)

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)

        // Then
        DispatchQueue.main.async {
            XCTAssertEqual(observer.currentStatus, .reachable(type: .ethernetOrWiFi))
        }
    }

    func test_currentStatus_returns_correctly_when_network_is_unsatisfied() {
        // Given
        let network = MockNetwork(status: .unsatisfied, currentInterface: .wifi)
        let networkMonitor = MockNetworkMonitor(currentNetwork: network)

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)

        // Then
        DispatchQueue.main.async {
            XCTAssertEqual(observer.currentStatus, .notReachable)
        }
    }

    func test_updateListener_returns_correct_status_in_callback_closure() {
        // Given
        let network = MockNetwork(status: .satisfied, currentInterface: .wifi)
        let networkMonitor = MockNetworkMonitor(currentNetwork: network)
        let networkUpdate = MockNetwork(status: .satisfied, currentInterface: .cellular)

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        var result: ConnectivityStatus = .unknown
        observer.updateListener { status in
            result = status
        }
        networkMonitor.fakeNetworkUpdate(network: networkUpdate)

        // Then
        DispatchQueue.main.async {
            XCTAssertEqual(result, .reachable(type: .cellular))
        }
    }
}

final class MockNetworkMonitor: NetworkMonitoring {
    let currentNetwork: NetworkMonitorable

    var networkUpdateHandler: ((NetworkMonitorable) -> Void)?

    private(set) var didStartMonitoring = false
    private(set) var didStopMonitoring = false

    init(currentNetwork: NetworkMonitorable) {
        self.currentNetwork = currentNetwork
    }

    func fakeNetworkUpdate(network: NetworkMonitorable) {
        networkUpdateHandler?(network)
    }

    func start(queue: DispatchQueue) {
        didStartMonitoring = true
    }

    func cancel() {
        didStopMonitoring = true
    }
}

struct MockNetwork: NetworkMonitorable {
    let status: NWPath.Status
    private let currentInterface: NWInterface.InterfaceType

    init(status: NWPath.Status, currentInterface: NWInterface.InterfaceType) {
        self.status = status
        self.currentInterface = currentInterface
    }

    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        type == currentInterface
    }
}
