import Foundation
import Yosemite

struct ReceiptActionCoordinator {
    static func printReceipt(for order: Order, params: CardPresentReceiptParameters) {
        ServiceLocator.analytics.track(.receiptPrintTapped)

        let action = ReceiptAction.print(order: order, parameters: params) { (result) in
            switch result {
            case .success:
                ServiceLocator.analytics.track(.receiptPrintSuccess)
            case .cancel:
                ServiceLocator.analytics.track(.receiptPrintCanceled)
            case .failure(let error):
                ServiceLocator.analytics.track(.receiptPrintFailed, withError: error)
                DDLogError("⛔️ Failed to print receipt: \(error.localizedDescription)")
            }
        }

        ServiceLocator.stores.dispatch(action)
    }
}
