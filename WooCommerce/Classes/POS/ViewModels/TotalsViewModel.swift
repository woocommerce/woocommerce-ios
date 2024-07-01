import SwiftUI
import struct Yosemite.POSOrder
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class TotalsViewModel: ObservableObject {

    @Published private(set) var isSyncingOrder: Bool = false

    /// Order created the first time the checkout is shown for a given transaction.
    /// If the merchant goes back to the product selection screen and makes changes, this should be updated when they return to the checkout.
    @Published private(set) var order: POSOrder?

    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        // TODO:
        // Remove ServiceLocator dependency
        return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount(price, with: currency)
    }

    var formattedOrderTotalPrice: String? {
        formattedPrice(order?.total, currency: order?.currency)
    }

    var formattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

    var showRecalculateButton: Bool {
        !areAmountsFullyCalculated &&
        isSyncingOrder == false
    }

    func startSyncOrder() {
        isSyncingOrder = true
    }

    func stopSyncOrder() {
        isSyncingOrder = false
    }

    func clearOrder() {
        order = nil
    }

    func setOrder(updatedOrder: POSOrder) {
        order = updatedOrder
    }

    var areAmountsFullyCalculated: Bool {
        isSyncingOrder == false &&
        formattedOrderTotalTaxPrice != nil &&
        formattedOrderTotalPrice != nil
    }

}
