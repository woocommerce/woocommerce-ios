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
        ServiceLocator.analytics.track(.receiptPrintTapped)
        let action = ReceiptAction.print(order: order, parameters: receipt) { (result) in
            switch result {
            case .success:
                ServiceLocator.analytics.track(.receiptPrintSuccess)
            case .cancel:
                ServiceLocator.analytics.track(.receiptPrintCanceled)
            case .failure(let error):
                ServiceLocator.analytics.track(.receiptPrintFailed, withError: error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }
}
