import Combine

/// A receipt printer discovered during printer discovery.
public struct PrinterDevice: Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// The state of an in-progress printer discovery, for presentation.
public enum PrinterDiscoveryState: Hashable, Identifiable, Sendable {
    public var id: Self {
        self
    }

    case searching
    case found([PrinterDevice])
    case error
    case connecting
}

/// The connection status of a receipt printer.
public enum PrinterConnectionStatus: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

/// Provides receipt-printer capabilities to POS: device discovery and the connection lifecycle.
///
/// Concrete backends (e.g. Star, AirPrint) live in the app target and are injected into the
/// aggregate model, so additional backends can be added without changes inside the POS module.
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
