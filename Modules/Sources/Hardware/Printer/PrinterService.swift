/// Abstracts the integration with a Receipt Printer
///
/// Isolated to the main actor because printing is driven by UIKit (`UIPrintInteractionController`).
@MainActor
public protocol PrinterService {
    /// Prints a receipt
    /// - Parameter ReceiptContent: the data that needs to be printed in the receipt
    func printReceipt(content: ReceiptContent, completion: @escaping (PrintingResult) -> Void)
}
