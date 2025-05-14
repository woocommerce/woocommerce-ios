import Foundation
import Yosemite
import WooFoundation

/// View model for `WooShippingRefundView`
///
final class WooShippingRefundViewModel {
    private let shippingLabel: ShippingLabel
    private let stores: StoresManager

    let formattedPurchaseDate: String
    let formattedRefundAmount: String
    let refundDuration: Int

    init(shippingLabel: ShippingLabel,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.stores = stores
        self.shippingLabel = shippingLabel
        self.refundDuration = shippingLabel.refundDuration

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        formattedRefundAmount = currencyFormatter.formatAmount(shippingLabel.refundableAmount.description) ?? shippingLabel.refundableAmount.description

        formattedPurchaseDate = shippingLabel.dateCreated.formatted(date: .abbreviated, time: .omitted)
    }

    @MainActor
    func submitRefundRequest() async throws -> ShippingLabel {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WooShippingAction.refundShippingLabel(shippingLabel: shippingLabel) { result in
                continuation.resume(with: result)
            })
        }
    }
}
