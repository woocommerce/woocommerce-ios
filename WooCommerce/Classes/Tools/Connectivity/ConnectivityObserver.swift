import Foundation

protocol ConnectivityObserver {
    /// Starts the observer with a listener.
    func startObserving(listener: @escaping (ConnectivityStatus) -> Void)

    /// Stops the observer.
    func stopObserving()
}

/// Defines the various states of network connectivity.
///
/// - unknown:      It is unknown whether the network is reachable.
/// - notReachable: The network is not reachable.
/// - reachable:    The network is reachable.
enum ConnectivityStatus {
    case unknown
    case notReachable
    case reachable(type: ConnectionType)
}

/// Defines the various connection types detected.
///
/// - ethernetOrWiFi: The connection type is either over Ethernet or WiFi.
/// - wwan:           The connection type is a WWAN connection.
enum ConnectionType {
    case ethernetOrWiFi
    case wwan
}
