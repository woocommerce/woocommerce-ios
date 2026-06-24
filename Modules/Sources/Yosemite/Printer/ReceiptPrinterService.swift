import Hardware

/// Provides receipt-printer capabilities to callers: device discovery and the connection lifecycle.
///
/// Manufacturer-agnostic. The concrete service owns the only reference to the printer SDK in the
/// Yosemite layer, so the app target and the POS module reach printers without importing Hardware.
public protocol ReceiptPrinterServiceProtocol: AnyObject {
    /// Streams the printer connection status. Each call returns its own stream, which replays the
    /// current status immediately on subscription and then emits every subsequent change.
    func connectionStatusUpdates() -> AsyncStream<PrinterConnectionStatus>

    /// Starts discovering available printers, emitting each device as it is found.
    func discover() -> AsyncThrowingStream<PrinterDevice, Error>

    /// Stops the current printer discovery.
    func stopDiscovery() async

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
///
/// Renders the receipt to text in this layer and hands the finished text to the Hardware backend,
/// keeping all receipt content and layout out of the printer SDK.
public final class ReceiptPrinterService: ReceiptPrinterServiceProtocol {
    private let printerDiscoveryService: PrinterDiscoveryService
    private let receiptTextRenderer: ReceiptTextRenderer

    public init(printerDiscoveryService: PrinterDiscoveryService,
                receiptTextRenderer: ReceiptTextRenderer = ReceiptTextRenderer()) {
        self.printerDiscoveryService = printerDiscoveryService
        self.receiptTextRenderer = receiptTextRenderer
    }

    public func connectionStatusUpdates() -> AsyncStream<PrinterConnectionStatus> {
        printerDiscoveryService.connectionStatusUpdates()
    }

    public func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        printerDiscoveryService.discover()
    }

    public func stopDiscovery() async {
        await printerDiscoveryService.stopDiscovery()
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
        let text = receiptTextRenderer.makeReceiptText(content: content,
                                                       storeInformation: storeInformation,
                                                       cardDetails: cardDetails)
        try await printerDiscoveryService.printReceipt(text: text)
    }
}
