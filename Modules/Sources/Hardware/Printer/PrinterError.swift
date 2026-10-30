import Foundation

/// Errors surfaced by a printer discovery/connection service, independent of manufacturer.
public enum PrinterError: Error, Equatable {
    case discoveryFailure
    case printerNotFound
    case connectionInProgress
    case printerNotConnected
    case paperEmpty
    case coverOpen
    /// The link to the printer failed: it is off, out of range, or Bluetooth is unavailable.
    case connectionLost(detail: String)
    case printFailed(detail: String)
}

/// Keeps the SDK's message in `error_description`, so analytics can still tell failures apart after
/// they are grouped into these cases.
extension PrinterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .connectionLost(let detail), .printFailed(let detail):
            return detail
        case .discoveryFailure, .printerNotFound, .connectionInProgress, .printerNotConnected, .paperEmpty, .coverOpen:
            return nil
        }
    }
}
