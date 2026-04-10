import Combine
import struct Hardware.ReceiptContent
import enum Hardware.DeviceStatus

/// A printer device discovered during printer discovery.
public struct PrinterDevice: Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// Represents the state of printer discovery.
public enum PrinterDiscoveryState: Hashable, Identifiable {
    public var id: Self {
        self
    }

    case searching
    case found([PrinterDevice])
    case error
    case connecting
}

/// Protocol that provides receipt printer capabilities for POS.
/// Concrete implementations live in the app target and are injected via the aggregate model.
public protocol POSReceiptPrinterProviding: AnyObject {
    /// Publishes the current printer connection status.
    var statusPublisher: AnyPublisher<DeviceStatus, Never> { get }

    /// Starts discovering available printers.
    func discover() -> AsyncThrowingStream<PrinterDevice, Error>

    /// Stops the current printer discovery.
    func stopDiscovery()

    /// Connects to a specific printer.
    func connect(to printer: PrinterDevice)

    /// Disconnects from the current printer.
    func disconnect() async

    /// Prints a receipt with the given content.
    func printReceipt(content: ReceiptContent) async throws
}
