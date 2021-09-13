import class Alamofire.NetworkReachabilityManager
import Foundation

final class DefaultConnectivityObserver: ConnectivityObserver {

    /// Reachability manager with WordPress API host to evaluate connection.
    ///
    private let reachabilityManager = NetworkReachabilityManager(host: "public-api.wordpress.com")

    func startObserving(listener: @escaping (ConnectivityStatus) -> Void) {
        reachabilityManager?.listener = { status in
            listener(ConnectivityStatus(reachabilityStatus: status))
        }
        reachabilityManager?.startListening()
    }

    func stopObserving() {
        reachabilityManager?.stopListening()
    }
}

extension ConnectivityStatus {
    init(reachabilityStatus: NetworkReachabilityManager.NetworkReachabilityStatus) {
        switch reachabilityStatus {
        case .unknown:
            self = .unknown
        case .notReachable:
            self = .notReachable
        case .reachable(let type):
            let matchingType = ConnectionType(connectionType: type)
            self = .reachable(type: matchingType)
        }
    }
}

extension ConnectionType {
    init(connectionType: NetworkReachabilityManager.ConnectionType) {
        switch connectionType {
        case .ethernetOrWiFi:
            self = .ethernetOrWiFi
        case .wwan:
            self = .wwan
        }
    }
}
