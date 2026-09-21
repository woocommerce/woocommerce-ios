import Combine
import Network

// State uses a thread-safe subject with concurrent reads and sends serialized on the main queue.
public final class DefaultConnectivityObserver: ConnectivityObserver, @unchecked Sendable {

    private struct Snapshot: Sendable {
        let status: ConnectivityStatus
        let isConnectionMetered: Bool?
        let isLowDataModeEnabled: Bool?

        static let initial = Snapshot(status: .unknown, isConnectionMetered: nil, isLowDataModeEnabled: nil)
    }

    /// Network monitor to evaluate connection.
    ///
    private let networkMonitor: NetworkMonitoring
    private let observingQueue: DispatchQueue = .global(qos: .background)

    private let stateSubject = CurrentValueSubject<Snapshot, Never>(.initial)

    public var currentStatus: ConnectivityStatus { stateSubject.value.status }
    public var isConnectionMetered: Bool? { stateSubject.value.isConnectionMetered }
    public var isLowDataModeEnabled: Bool? { stateSubject.value.isLowDataModeEnabled }

    public var statusPublisher: AnyPublisher<ConnectivityStatus, Never> {
        stateSubject.map(\.status).eraseToAnyPublisher()
    }

    public convenience init() {
        self.init(networkMonitor: NWPathMonitor())
    }

    init(networkMonitor: NetworkMonitoring = NWPathMonitor()) {
        self.networkMonitor = networkMonitor
        networkMonitor.networkUpdateHandler = { [weak self] path in
            guard let self else { return }
            DispatchQueue.main.async {
                // Swap the whole snapshot before publishing, so a subscriber reacting to a status change reads the
                // flags from that same path. Main-queue synchronous subscribers get that guarantee; off-main replay
                // or asynchronously delivered events may observe a newer snapshot through the getters.
                let next = Snapshot(status: self.connectivityStatus(from: path),
                                    isConnectionMetered: path.isExpensive,
                                    isLowDataModeEnabled: path.isConstrained)
                self.stateSubject.send(next)
            }
        }
        startObserving()
    }

    private func startObserving() {
        networkMonitor.start(queue: observingQueue)
    }

    func stopObserving() {
        networkMonitor.cancel()
    }

    private func connectivityStatus(from path: NetworkMonitorable) -> ConnectivityStatus {
        let connectivityStatus: ConnectivityStatus
        switch path.status {
        case .satisfied:
            var connectionType: ConnectionType = .other
            if path.usesInterfaceType(.wifi) ||
                path.usesInterfaceType(.wiredEthernet) {
                connectionType = .ethernetOrWiFi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            }
            connectivityStatus = .reachable(type: connectionType)
        case .unsatisfied:
            connectivityStatus = .notReachable
        case .requiresConnection:
            connectivityStatus = .unknown
        @unknown default:
            connectivityStatus = .unknown
        }
        return connectivityStatus
    }
}

// MARK: - Testability

/// Proxy protocol for mocking `NWPathMonitor`.
protocol NetworkMonitoring: AnyObject {
    /// A handler that receives network updates.
    var networkUpdateHandler: (@Sendable (NetworkMonitorable) -> Void)? { get set }

    /// Starts monitoring network changes, and sets a queue on which to deliver events.
    func start(queue: DispatchQueue)

    /// Stops receiving network monitoring updates.
    func cancel()
}

/// Proxy protocol for mocking `NWPath`.
protocol NetworkMonitorable: Sendable {
    /// A status indicating whether a network can be used by connections.
    var status: NWPath.Status { get }

    /// Whether the path uses an interface the system considers expensive.
    var isExpensive: Bool { get }

    /// Whether the path uses an interface constrained by Low Data Mode.
    var isConstrained: Bool { get }

    /// Checks if the network uses an NWInterface with the specified type
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool
}

extension NWPath: NetworkMonitorable {}
extension NWPathMonitor: NetworkMonitoring {
    var networkUpdateHandler: (@Sendable (NetworkMonitorable) -> Void)? {
        get {
            let closure: (@Sendable (NetworkMonitorable) -> Void)? = {
                [weak self] network in
                guard let path = network as? NWPath else {
                    return
                }
                self?.pathUpdateHandler?(path)
            }
            return closure
        }
        set {
            pathUpdateHandler = newValue
        }
    }
}
