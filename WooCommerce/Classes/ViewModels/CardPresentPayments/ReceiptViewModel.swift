import Yosemite

/// ViewModel supporting the receipt preview.
final class ReceiptViewModel {
    private let order: Order
    private let receipt: CardPresentReceiptParameters


    /// Initializer
    /// - Parameters:
    ///   - order: The order associated with the receipt
    ///   - receipt: the receipt metadata
    init(order: Order, receipt: CardPresentReceiptParameters) {
        self.order = order
        self.receipt = receipt
    }


    /// Get the receipt content
    /// - Parameter onCompletion: a closure containing the receipt content as a HTML string
    func generateContent(onCompletion: @escaping (String) -> Void) {
        let action = ReceiptAction.generateContent(order: order, parameters: receipt) { receiptContent in
            onCompletion(receiptContent)
        }

        ServiceLocator.stores.dispatch(action)
    }


    /// Prints the receipt
    func printReceipt() {
        ReceiptPrintingCoordinator.printReceipt(for: order, params: receipt)
    }
}
