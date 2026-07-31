import Combine

/// Interface for the observing connectivity
///
public protocol ConnectivityObserver {
    /// Getter for current state of the connectivity.
    var currentStatus: ConnectivityStatus { get }

    /// Whether the system considers the current network path expensive — typically cellular or a personal
    /// hotspot. `nil` until the first path update arrives.
    var isCurrentPathExpensive: Bool? { get }

    /// Whether Low Data Mode constrains the current network path. `nil` until the first path update arrives.
    var isCurrentPathConstrained: Bool? { get }

    /// Publisher for connectivity availability.
    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> { get }
}

public extension ConnectivityObserver {
    var isCurrentPathExpensive: Bool? { nil }
    var isCurrentPathConstrained: Bool? { nil }
}

/// Defines the various states of network connectivity.
///
/// - unknown:      It is unknown whether the network is reachable.
/// - notReachable: The network is not reachable.
/// - reachable:    The network is reachable.
public enum ConnectivityStatus: Equatable {
    case unknown
    case notReachable
    case reachable(type: ConnectionType)
}

/// Defines the various connection types detected.
///
/// - ethernetOrWiFi: The connection type is either over Ethernet or WiFi.
/// - cellular:       The connection type is a cellular connection.
/// - other:          The connection type is via a local loopback network, virtual network or other unknown types.
public enum ConnectionType: Equatable {
    case ethernetOrWiFi
    case cellular
    case other
}
