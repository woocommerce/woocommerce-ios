/// Abstracts the integration with a Receipt Printer
public protocol PrinterService {
    /// Prints a receipt
    /// - Parameter ReceiptContent: the data that needs to be printed in the receipt
    func printReceipt(content: ReceiptContent, completion: @escaping (PrintingResult) -> Void)
}
