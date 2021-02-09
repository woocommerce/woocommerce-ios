/// Models the Connection Status of a Card Reader
public enum ConnectionStatus {
    /// The service is currently connecting to a reader
    case connecting

    /// The service is currently connected to a reader
    case connected

    /// The service is currently not connected to a reader
    case notConnected
}
