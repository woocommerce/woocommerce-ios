import Foundation

/// Errors surfaced by a printer discovery/connection service, independent of manufacturer.
public enum PrinterError: Error, Equatable {
    case discoveryFailure
    case printerNotFound
    case connectionInProgress
    case printerNotConnected
}
