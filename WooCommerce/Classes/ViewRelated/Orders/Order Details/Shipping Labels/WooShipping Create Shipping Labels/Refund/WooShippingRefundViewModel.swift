import Foundation
import Yosemite
import WooFoundation

/// View model for `WooShippingRefundView`
///
final class WooShippingRefundViewModel {
    private let stores: StoresManager

    private(set) var formattedPurchaseDate: String
    private(set) var formattedRefundAmount: String

    init(refundableAmount: Double,
         purchaseDate: Date,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.stores = stores

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        formattedRefundAmount = currencyFormatter.formatAmount(refundableAmount.description) ?? refundableAmount.description

        formattedPurchaseDate = purchaseDate.formatted(date: .abbreviated, time: .omitted)
    }

    func submitRefundRequest() {
        // TODO: integrate refund API
    }
}
