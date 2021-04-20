/// Abstracts the integration with a Receipt Printer
public protocol ReceiptPrinterService {

    /// Signals if the printing service is available.
    var isPrintingAvilable: Bool { get }

    /// Prints a receipt
    /// - Parameter ReceiptContent: the data that needs to be printed in the receipt
    func printReceipt(content: ReceiptContent)
}
