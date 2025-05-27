import Foundation
import Yosemite
import WooFoundation

/// View model for `WooShippingRefundView`
///
final class WooShippingRefundViewModel {
    private let shippingLabel: ShippingLabel
    private let stores: StoresManager
    private let analytics: Analytics

    let formattedPurchaseDate: String
    let formattedRefundAmount: String
    let refundDuration: Int

    init(shippingLabel: ShippingLabel,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.shippingLabel = shippingLabel
        self.refundDuration = shippingLabel.refundDuration
        self.analytics = analytics

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        formattedRefundAmount = currencyFormatter.formatAmount(shippingLabel.refundableAmount.description) ?? shippingLabel.refundableAmount.description

        formattedPurchaseDate = shippingLabel.dateCreated.formatted(date: .abbreviated, time: .omitted)
    }

    @MainActor
    func submitRefundRequest() async throws -> ShippingLabel {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WooShippingAction.refundShippingLabel(shippingLabel: shippingLabel) { [weak self] result in
                let error = result.failure
                self?.analytics.track(event: .WooShipping.refundRequested(error: error))
                continuation.resume(with: result)
            })
        }
    }
}
