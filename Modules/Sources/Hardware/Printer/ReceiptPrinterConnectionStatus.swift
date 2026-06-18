import Foundation

/// The connection status of a receipt printer.
public enum ReceiptPrinterConnectionStatus: Equatable, Sendable {
    /// Initial state, before any connection has been attempted.
    case idle
    case disconnected
    case connecting
    case connected
    case disconnecting
}
