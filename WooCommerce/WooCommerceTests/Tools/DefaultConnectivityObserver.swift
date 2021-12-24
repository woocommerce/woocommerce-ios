import Combine
import Network
import XCTest
@testable import WooCommerce

final class DefaultConnectivityObserverTests: XCTestCase {
    private var subscriptions: Set<AnyCancellable> = []

    func test_initializing_observer_triggers_network_monitoring() {
        // Given
        let networkMonitor = MockNetworkMonitor()

        // When
        let _ = DefaultConnectivityObserver(networkMonitor: networkMonitor)

        // Then
        XCTAssertTrue(networkMonitor.didStartMonitoring)
    }

    func test_stopping_observer_stops_network_monitoring() {
        // Given
        let networkMonitor = MockNetworkMonitor()

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        observer.stopObserving()

        // Then
        XCTAssertTrue(networkMonitor.didStopMonitoring)
    }

    func test_currentStatus_and_statusPublisher_return_correctly_when_network_is_satisfied() {
        // Given
        let networkMonitor = MockNetworkMonitor()
        let expectation = expectation(description: "Current status and status publisher values")

        // When
        var result: ConnectivityStatus = .unknown
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        observer.statusPublisher
            .dropFirst()
            .sink { status in
                result = status
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        networkMonitor.fakeNetworkUpdate(network: MockNetwork(status: .satisfied, currentInterface: .wifi))

        // Then
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(observer.currentStatus, .reachable(type: .ethernetOrWiFi))
        XCTAssertEqual(result, .reachable(type: .ethernetOrWiFi))
    }

    func test_currentStatus_and_statusPublisher_return_correctly_when_network_is_unsatisfied() {
        // Given
        let networkMonitor = MockNetworkMonitor()
        let expectation = expectation(description: "Current status and status publisher values")

        // When
        var result: ConnectivityStatus = .unknown
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        observer.statusPublisher
            .dropFirst()
            .sink { status in
                result = status
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        networkMonitor.fakeNetworkUpdate(network: MockNetwork(status: .unsatisfied, currentInterface: .wifi))

        // Then
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(observer.currentStatus, .notReachable)
        XCTAssertEqual(result, .notReachable)
    }
}

final class MockNetworkMonitor: NetworkMonitoring {
    var networkUpdateHandler: ((NetworkMonitorable) -> Void)?

    private(set) var didStartMonitoring = false
    private(set) var didStopMonitoring = false

    init() {}

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
