import Yosemite

/// ViewModel supporting the receipt preview.
final class ReceiptViewModel {
    private let order: Order
    private let receipt: CardPresentReceiptParameters
    private let countryCode: String


    /// Initializer
    /// - Parameters:
    ///   - order: the order associated with the receipt
    ///   - receipt: the receipt metadata
    ///   - countryCode: the country code of the store
    init(order: Order, receipt: CardPresentReceiptParameters, countryCode: String) {
        self.order = order
        self.receipt = receipt
        self.countryCode = countryCode
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
        ReceiptActionCoordinator.printReceipt(for: order,
                                              params: receipt,
                                              countryCode: countryCode,
                                              cardReaderModel: nil,
                                              stores: ServiceLocator.stores,
                                              analytics: ServiceLocator.analytics)
    }
}
