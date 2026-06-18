// MARK: - ReceiptPrinterAction: Defines all of the Actions supported by the ReceiptPrinterStore.
//

import Combine

public enum ReceiptPrinterAction: Action {
    /// Hands back a publisher of the current printer connection status.
    ///
    case connectionStatusPublisher(onPublisher: (AnyPublisher<PrinterConnectionStatus, Never>) -> Void)

    /// Starts discovering printers, handing back a stream that emits each device as it is found.
    ///
    case discover(onStream: (AsyncThrowingStream<PrinterDevice, Error>) -> Void)

    /// Stops the current printer discovery.
    ///
    case stopDiscovery

    /// Connects to the given printer.
    ///
    case connect(printer: PrinterDevice, completion: (Result<Void, Error>) -> Void)

    /// Disconnects from the currently connected printer, if any.
    ///
    case disconnect(completion: () -> Void)

    /// Prints a receipt on the connected printer.
    ///
    /// `cardDetails` are included in the printed card/EMV block when present; pass `nil` for
    /// cash and other payment methods so the receipt prints without card fields.
    ///
    case printReceipt(content: ReceiptContent,
                      storeInformation: ReceiptStoreInformation,
                      cardDetails: CardPresentTransactionDetails?,
                      completion: (PrintingResult) -> Void)
}
