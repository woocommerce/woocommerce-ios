import Combine

/// Interface for the observing connectivity
///
protocol ConnectivityObserver {
    /// Getter for current state of the connectivity.
    var currentStatus: ConnectivityStatus { get }

    /// Publisher for connectivity availability.
    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> { get }

    /// Starts the observer.
    func startObserving()

    /// Stops the observer.
    func stopObserving()
}

/// Defines the various states of network connectivity.
///
/// - unknown:      It is unknown whether the network is reachable.
/// - notReachable: The network is not reachable.
/// - reachable:    The network is reachable.
enum ConnectivityStatus: Equatable {
    case unknown
    case notReachable
    case reachable(type: ConnectionType)
}

/// Defines the various connection types detected.
///
/// - ethernetOrWiFi: The connection type is either over Ethernet or WiFi.
/// - cellular:       The connection type is a cellular connection.
/// - other:          The connection type is via a local loopback network, virtual network or other unknown types.
enum ConnectionType: Equatable {
    case ethernetOrWiFi
    case cellular
    case other
}
