/// Abstracts the integration with a Receipt Printer
public protocol ReceiptPrinterService {
    /// Prints a receipt
    /// - Parameter ReceiptContent: the data that needs to be printed in the receipt
    func printReceipt(content: ReceiptContent)
}
