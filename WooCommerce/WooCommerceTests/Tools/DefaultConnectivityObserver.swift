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

    func test_isConnectivityAvailable_returns_true_when_network_is_satisfied() {
        // Given
        let network = MockNetwork(status: .satisfied, currentInterface: .wifi)
        let networkMonitor = MockNetworkMonitor(currentNetwork: network)

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)

        // Then
        XCTAssertTrue(observer.isConnectivityAvailable)
    }

    func test_isConnectivityAvailable_returns_false_when_network_is_unsatisfied() {
        // Given
        let network = MockNetwork(status: .unsatisfied, currentInterface: .wifi)
        let networkMonitor = MockNetworkMonitor(currentNetwork: network)

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)

        // Then
        XCTAssertFalse(observer.isConnectivityAvailable)
    }

    func test_updateListener_returns_correct_status_in_callback_closure() {
        // Given
        let network = MockNetwork(status: .satisfied, currentInterface: .wifi)
        let networkMonitor = MockNetworkMonitor(currentNetwork: network)
        let networkUpdate = MockNetwork(status: .satisfied, currentInterface: .cellular)
        let statusExpectation = expectation(description: "Status in callback closure")

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        var result: ConnectivityStatus = .unknown
        observer.updateListener { status in
            result = status
            statusExpectation.fulfill()
        }
        networkMonitor.fakeNetworkUpdate(network: networkUpdate)

        // Then
        waitForExpectations(timeout: 0.3, handler: nil)
        if case .reachable(let type) = result {
            XCTAssertEqual(type, .cellular)
        } else {
            XCTFail("Incorrect result status in callback closure")
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
