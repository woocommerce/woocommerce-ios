@testable import Hardware

/// Supports tests for ReceiptStore
final class MockReceiptPrinterService: PrinterService {
    /// Boolean flag indicating method printReceipt has been hit
    var printWasCalled: Bool = false

    /// The parameter passed to the printReceipt method
    var contentProvided: ReceiptContent?

    func printReceipt(content: ReceiptContent, completion: @escaping (PrintingResult) -> Void) {
        printWasCalled = true
        contentProvided = content
        completion(.success)
    }
}
