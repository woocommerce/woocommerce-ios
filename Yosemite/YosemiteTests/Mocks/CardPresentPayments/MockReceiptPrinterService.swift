@testable import Hardware

/// Supports tests for ReceiptStore
final class MockReceiptPrinterService: ReceiptPrinterService {
    /// Boolean flag indicating metod printReceipt has been hit
    var printWasCalled: Bool = false

    /// The parameter passed to the printReceipt method
    var contentProvided: ReceiptContent?

    func printReceipt(content: ReceiptContent) {
        printWasCalled = true
        contentProvided = content
    }
}
