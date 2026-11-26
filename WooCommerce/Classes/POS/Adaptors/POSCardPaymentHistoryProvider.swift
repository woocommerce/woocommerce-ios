import Foundation
import PointOfSale
import enum Yosemite.AppSettingsAction
import protocol Yosemite.StoresManager

/// Reads the card payments this device has recorded for a store, by Tap to Pay or a card reader, in POS or elsewhere in the app.
@MainActor
final class POSCardPaymentHistoryProvider: POSCardPaymentHistoryProviding {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func hasRecordedCardPayment(siteID: Int64) async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadSiteHasAtLeastOneIPPTransactionFinished(siteID: siteID) { hasRecordedPayment in
                continuation.resume(returning: hasRecordedPayment)
            })
        }
    }
}
