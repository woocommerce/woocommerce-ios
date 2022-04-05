import Foundation
import Yosemite

struct ReceiptActionCoordinator {
    static func printReceipt(for order: Order, params: CardPresentReceiptParameters, countryCode: String) {
        ServiceLocator.analytics.track(event: .InPersonPayments.receiptPrintTapped(countryCode: countryCode))

        let action = ReceiptAction.print(order: order, parameters: params) { (result) in
            switch result {
            case .success:
                ServiceLocator.analytics.track(event: .InPersonPayments.receiptPrintSuccess(countryCode: countryCode))
            case .cancel:
                ServiceLocator.analytics.track(event: .InPersonPayments.receiptPrintCanceled(countryCode: countryCode))
            case .failure(let error):
                ServiceLocator.analytics.track(event: .InPersonPayments.receiptPrintFailed(error: error, countryCode: countryCode))
                DDLogError("⛔️ Failed to print receipt: \(error.localizedDescription)")
            }
        }

        ServiceLocator.stores.dispatch(action)
    }
}
