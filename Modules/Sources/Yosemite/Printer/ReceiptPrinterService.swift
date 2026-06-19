import Combine
import Hardware

/// Provides receipt-printer capabilities to callers: device discovery and the connection lifecycle.
///
/// Manufacturer-agnostic. The concrete service owns the only reference to the printer SDK in the
/// Yosemite layer, so the app target and the POS module reach printers without importing Hardware.
public protocol ReceiptPrinterServiceProtocol: AnyObject {
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

    /// Prints a receipt on the connected printer.
    ///
    /// `cardDetails` are included in the printed card/EMV block when present; pass `nil` for
    /// cash and other payment methods so the receipt prints without card fields.
    func printReceipt(content: ReceiptContent,
                      storeInformation: ReceiptStoreInformation,
                      cardDetails: CardPresentTransactionDetails?) async throws
}

/// Default `ReceiptPrinterServiceProtocol`, backed by an injected Hardware discovery service.
public final class ReceiptPrinterService: ReceiptPrinterServiceProtocol {
    private let printerDiscoveryService: PrinterDiscoveryService

    public init(printerDiscoveryService: PrinterDiscoveryService) {
        self.printerDiscoveryService = printerDiscoveryService
    }

    public var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> {
        printerDiscoveryService.connectionStatusPublisher
    }

    public func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        printerDiscoveryService.discover()
    }

    public func stopDiscovery() {
        printerDiscoveryService.stopDiscovery()
    }

    public func connect(to printer: PrinterDevice) async throws {
        try await printerDiscoveryService.connect(to: printer)
    }

    public func disconnect() async {
        await printerDiscoveryService.disconnect()
    }

    public func printReceipt(content: ReceiptContent,
                             storeInformation: ReceiptStoreInformation,
                             cardDetails: CardPresentTransactionDetails?) async throws {
        try await printerDiscoveryService.printReceipt(content: content,
                                                       storeInformation: storeInformation,
                                                       cardDetails: cardDetails)
    }
}
