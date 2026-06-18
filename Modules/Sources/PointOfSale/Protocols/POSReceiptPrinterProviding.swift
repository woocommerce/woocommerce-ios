import Combine
import struct Yosemite.PrinterDevice
import enum Yosemite.PrinterConnectionStatus

/// The state of an in-progress printer discovery, for presentation.
public enum PrinterDiscoveryState: Hashable, Identifiable, Sendable {
    public var id: Self {
        self
    }

    case idle
    case searching
    case found([PrinterDevice])
    case error
}

/// Provides receipt-printer capabilities to POS: device discovery and the connection lifecycle.
///
/// The concrete backend is injected into the aggregate model so it can be swapped or
/// extended without changes inside the POS module.
public protocol POSReceiptPrinterProviding: AnyObject {
    /// Publishes the current printer connection status.
    var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> { get }

    /// Starts discovering available printers, emitting each device as it is found.
    func discover() -> AsyncThrowingStream<PrinterDevice, Error>

    /// Stops the current printer discovery.
    func stopDiscovery()

    /// Connects to the given printer.
    func connect(to printer: PrinterDevice) async throws

    /// Disconnects from the currently connected printer, if any.
    func disconnect() async
}
