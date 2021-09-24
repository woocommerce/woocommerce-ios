import Combine
import Network

final class DefaultConnectivityObserver: ConnectivityObserver {

    /// Network monitor to evaluate connection.
    ///
    private let networkMonitor: NetworkMonitoring
    private let observingQueue: DispatchQueue = .global(qos: .background)

    @Published private(set) var currentStatus: ConnectivityStatus = .unknown

    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> {
        $currentStatus.eraseToAnyPublisher()
    }

    init(networkMonitor: NetworkMonitoring = NWPathMonitor()) {
        self.networkMonitor = networkMonitor
        startObserving()
        networkMonitor.networkUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentStatus = self.connectivityStatus(from: path)
            }
        }
    }

    func startObserving() {
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
    var networkUpdateHandler: ((NetworkMonitorable) -> Void)? { get set }

    /// Starts monitoring network changes, and sets a queue on which to deliver events.
    func start(queue: DispatchQueue)

    /// Stops receiving network monitoring updates.
    func cancel()
}

/// Proxy protocol for mocking `NWPath`.
protocol NetworkMonitorable {
    /// A status indicating whether a network can be used by connections.
    var status: NWPath.Status { get }

    /// Checks if the network uses an NWInterface with the specified type
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool
}

extension NWPath: NetworkMonitorable {}
extension NWPathMonitor: NetworkMonitoring {
    var networkUpdateHandler: ((NetworkMonitorable) -> Void)? {
        get {
            let closure: ((NetworkMonitorable) -> Void)? = {
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
