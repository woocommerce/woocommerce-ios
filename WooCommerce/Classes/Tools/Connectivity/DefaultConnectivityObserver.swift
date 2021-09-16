import Foundation
import Network

final class DefaultConnectivityObserver: ConnectivityObserver {

    /// Network monitor to evaluate connection.
    ///
    private let networkMonitor: NWPathMonitor
    private let observingQueue: DispatchQueue = .global(qos: .background)

    init(networkMonitor: NWPathMonitor = .init()) {
        self.networkMonitor = networkMonitor
    }

    func startObserving() {
        networkMonitor.start(queue: observingQueue)
    }

    func updateListener(_ listener: @escaping (ConnectivityStatus) -> Void) {
        if networkMonitor.pathUpdateHandler == nil {
            startObserving()
        }
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let connectivityStatus = self.connectivityStatus(from: path)
            DispatchQueue.main.async {
                listener(connectivityStatus)
            }
        }
    }

    func stopObserving() {
        networkMonitor.cancel()
    }

    private func connectivityStatus(from path: NWPath) -> ConnectivityStatus {
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
