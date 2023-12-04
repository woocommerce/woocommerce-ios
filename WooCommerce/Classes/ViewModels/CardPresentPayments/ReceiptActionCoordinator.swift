import Foundation
import Yosemite
import WooFoundation

struct ReceiptActionCoordinator {
    static func printReceipt(for order: Order,
                             params: CardPresentReceiptParameters,
                             countryCode: CountryCode,
                             cardReaderModel: String?,
                             stores: StoresManager,
                             analytics: Analytics = ServiceLocator.analytics) async {
        analytics.track(event: .InPersonPayments.receiptPrintTapped(countryCode: countryCode, cardReaderModel: cardReaderModel))

         await withCheckedContinuation { continuation in
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

                continuation.resume()
            }

             Task { @MainActor in
                 stores.dispatch(action)
             }
        }
    }
}
