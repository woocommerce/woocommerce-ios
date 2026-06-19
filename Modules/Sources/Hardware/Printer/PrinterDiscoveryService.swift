import Combine

/// Discovers printers over Bluetooth, manages the connection lifecycle, and prints receipts.
///
/// Hardware-domain abstraction over the printer SDK. Concrete implementations wrap the
/// SDK and expose only Hardware-domain types, keeping SDK details inside the Hardware module.
public protocol PrinterDiscoveryService: AnyObject {
    /// Publishes the current printer connection status.
    var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> { get }

    /// Starts discovering available printers, emitting each device as it is found.
    func discover() -> AsyncThrowingStream<PrinterDevice, Error>

    /// Stops the current printer discovery.
    func stopDiscovery()

    /// Connects to the given printer.
    func connect(to device: PrinterDevice) async throws

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
