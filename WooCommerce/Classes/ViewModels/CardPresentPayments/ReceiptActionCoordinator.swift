import Foundation
import Yosemite

struct ReceiptActionCoordinator {
    static func printReceipt(for order: Order,
                             params: CardPresentReceiptParameters,
                             countryCode: String,
                             cardReaderModel: String?,
                             stores: StoresManager,
                             analytics: Analytics) {
        analytics.track(event: .InPersonPayments.receiptPrintTapped(countryCode: countryCode, cardReaderModel: cardReaderModel))

        let action = ReceiptAction.print(order: order, parameters: params) { (result) in
            switch result {
            case .success:
                analytics.track(event: .InPersonPayments.receiptPrintSuccess(countryCode: countryCode, cardReaderModel: cardReaderModel))
            case .cancel:
                analytics.track(event: .InPersonPayments.receiptPrintCanceled(countryCode: countryCode, cardReaderModel: cardReaderModel))
            case .failure(let error):
                analytics.track(event: .InPersonPayments.receiptPrintFailed(error: error, countryCode: countryCode, cardReaderModel: cardReaderModel))
                DDLogError("⛔️ Failed to print receipt: \(error.localizedDescription)")
            }
        }

        stores.dispatch(action)
    }
}
