import Foundation
import Yosemite
import WooFoundation

/// View model for `WooShippingRefundView`
///
final class WooShippingRefundViewModel {
    private let stores: StoresManager

    let formattedPurchaseDate: String
    let formattedRefundAmount: String
    let refundDuration: Int

    init(refundableAmount: Double,
         refundDuration: Int,
         purchaseDate: Date,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.stores = stores
        self.refundDuration = refundDuration

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        formattedRefundAmount = currencyFormatter.formatAmount(refundableAmount.description) ?? refundableAmount.description

        formattedPurchaseDate = purchaseDate.formatted(date: .abbreviated, time: .omitted)
    }

    func submitRefundRequest() {
        // TODO: integrate refund API
    }
}
