import Foundation

/// The connection status of a printer.
public enum PrinterConnectionStatus: Equatable, Sendable {
    /// Initial state, before any connection has been attempted.
    case idle
    case disconnected
    case connecting
    case connected(PrinterDevice)
    case disconnecting
}
