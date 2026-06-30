import Hardware
import Networking
import WooFoundation

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

    /// Prints a receipt for the given order on the connected printer.
    ///
    /// Assembles the receipt content from the order (line items, totals, note) so callers that
    /// only hold an `Order` — like POS — don't have to build Hardware receipt parameters. The
    /// printed receipt carries no card details in this form (`cardDetails: nil`).
    func printReceipt(order: Order,
                      storeInformation: ReceiptStoreInformation) async throws
}

/// Default `ReceiptPrinterServiceProtocol`, backed by an injected Hardware discovery service.
///
/// Renders the receipt to text in this layer and hands the finished text to the Hardware backend,
/// keeping all receipt content and layout out of the printer SDK.
public final class ReceiptPrinterService: ReceiptPrinterServiceProtocol {
    private let printerDiscoveryService: PrinterDiscoveryService
    private let receiptTextRenderer: ReceiptTextRenderer
    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
    private let contentAssembler = ReceiptContentAssembler()

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

    public func printReceipt(order: Order,
                             storeInformation: ReceiptStoreInformation) async throws {
        let parameters = receiptParameters(for: order)
        let content = contentAssembler.makeContent(order: order, parameters: parameters, removingHtml: true)
        try await printReceipt(content: content, storeInformation: storeInformation, cardDetails: nil)
    }

    private func receiptParameters(for order: Order) -> CardPresentReceiptParameters {
        let formattedAmount = currencyFormatter.formatAmount(order.total, with: order.currency) ?? order.total
        return CardPresentReceiptParameters(amount: 0,
                                            formattedAmount: formattedAmount,
                                            currency: order.currency,
                                            date: order.datePaid ?? order.dateCreated,
                                            storeName: nil,
                                            cardDetails: Self.placeholderCardDetails,
                                            orderID: order.orderID)
    }

    /// `CardPresentReceiptParameters.cardDetails` is non-optional, but this order-based path prints
    /// without card details. The renderer reads the separate `cardDetails:` argument (passed `nil`
    /// above), never `parameters.cardDetails`, so this value only satisfies the type.
    private static let placeholderCardDetails = CardPresentTransactionDetails(last4: "",
                                                                              expMonth: 0,
                                                                              expYear: 0,
                                                                              cardholderName: nil,
                                                                              brand: .unknown,
                                                                              generatedCard: nil,
                                                                              receipt: nil,
                                                                              emvAuthData: nil,
                                                                              wallet: nil,
                                                                              network: nil)
}
