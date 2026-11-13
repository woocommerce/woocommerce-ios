import Combine
import Network
import XCTest
@testable import WooFoundation

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

    func test_path_flags_are_nil_before_the_first_update_and_reflect_the_path_afterwards() {
        // Given
        let networkMonitor = MockNetworkMonitor()
        let expectation = expectation(description: "Path flags updated")
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        XCTAssertNil(observer.isConnectionMetered)
        XCTAssertNil(observer.isLowDataModeEnabled)

        // When
        observer.statusPublisher
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        networkMonitor.fakeNetworkUpdate(network: MockNetwork(status: .satisfied,
                                                              currentInterface: .cellular,
                                                              isExpensive: true,
                                                              isConstrained: true))

        // Then
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(observer.isConnectionMetered, true)
        XCTAssertEqual(observer.isLowDataModeEnabled, true)
    }

    func test_statusPublisher_when_path_updates_then_callback_reads_the_new_snapshot() {
        // Given
        let networkMonitor = MockNetworkMonitor()
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        let expectation = expectation(description: "Snapshot visible inside callback")
        observer.statusPublisher
            .dropFirst()
            .sink { status in
                XCTAssertEqual(status, .reachable(type: .cellular))
                XCTAssertEqual(observer.currentStatus, status)
                XCTAssertEqual(observer.isConnectionMetered, true)
                XCTAssertEqual(observer.isLowDataModeEnabled, true)
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        networkMonitor.fakeNetworkUpdate(network: MockNetwork(status: .satisfied,
                                                              currentInterface: .cellular,
                                                              isExpensive: true,
                                                              isConstrained: true))

        // Then
        wait(for: [expectation], timeout: 1)
    }

    func test_statusPublisher_when_subscribing_after_update_then_replays_the_current_snapshot() {
        // Given
        let networkMonitor = MockNetworkMonitor()
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        let expectation = expectation(description: "Path updated before subscribing")
        observer.statusPublisher
            .dropFirst()
            .sink { _ in expectation.fulfill() }
            .store(in: &subscriptions)
        networkMonitor.fakeNetworkUpdate(network: MockNetwork(status: .satisfied,
                                                              currentInterface: .cellular,
                                                              isExpensive: true,
                                                              isConstrained: true))
        wait(for: [expectation], timeout: 1)

        // When
        var replayedStatus: ConnectivityStatus?
        observer.statusPublisher
            .sink { status in
                replayedStatus = status
                XCTAssertEqual(observer.currentStatus, status)
                XCTAssertEqual(observer.isConnectionMetered, true)
                XCTAssertEqual(observer.isLowDataModeEnabled, true)
            }
            .store(in: &subscriptions)

        // Then
        XCTAssertEqual(replayedStatus, .reachable(type: .cellular))
    }

    func test_initializing_observer_when_monitor_updates_during_start_then_receives_the_update() {
        // Given
        let networkMonitor = MockNetworkMonitor(networkOnStart: MockNetwork(status: .satisfied, currentInterface: .wifi))
        let expectation = expectation(description: "Update delivered during start")

        // When
        let observer = DefaultConnectivityObserver(networkMonitor: networkMonitor)
        observer.statusPublisher
            .filter { $0 == .reachable(type: .ethernetOrWiFi) }
            .sink { _ in expectation.fulfill() }
            .store(in: &subscriptions)

        // Then
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(observer.currentStatus, .reachable(type: .ethernetOrWiFi))
    }
}

final class MockNetworkMonitor: NetworkMonitoring {
    var networkUpdateHandler: (@Sendable (NetworkMonitorable) -> Void)?

    private(set) var didStartMonitoring = false
    private(set) var didStopMonitoring = false
    private let networkOnStart: NetworkMonitorable?

    init(networkOnStart: NetworkMonitorable? = nil) {
        self.networkOnStart = networkOnStart
    }

    func fakeNetworkUpdate(network: NetworkMonitorable) {
        networkUpdateHandler?(network)
    }

    func start(queue: DispatchQueue) {
        didStartMonitoring = true
        if let networkOnStart {
            networkUpdateHandler?(networkOnStart)
        }
    }

    func cancel() {
        didStopMonitoring = true
    }
}

private struct MockNetwork: NetworkMonitorable {
    let status: NWPath.Status
    let isExpensive: Bool
    let isConstrained: Bool
    private let currentInterface: NWInterface.InterfaceType

    init(status: NWPath.Status,
         currentInterface: NWInterface.InterfaceType,
         isExpensive: Bool = false,
         isConstrained: Bool = false) {
        self.status = status
        self.currentInterface = currentInterface
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }

    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        type == currentInterface
    }
}
