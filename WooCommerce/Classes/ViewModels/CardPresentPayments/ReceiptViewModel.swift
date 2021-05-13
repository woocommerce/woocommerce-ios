import Yosemite

final class ReceiptViewModel {
    private let order: Order
    private let receipt: CardPresentReceiptParameters

    init(order: Order, receipt: CardPresentReceiptParameters) {
        self.order = order
        self.receipt = receipt
    }

    func generateContent(onCompletion: @escaping (String) -> Void) {
        let action = ReceiptAction.generateContent(order: order, parameters: receipt) { receiptContent in
            onCompletion(receiptContent)
        }

        ServiceLocator.stores.dispatch(action)
    }

    func printReceipt() {
        let action = ReceiptAction.print(order: order, parameters: receipt)

        ServiceLocator.stores.dispatch(action)
    }
}
