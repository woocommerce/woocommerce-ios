import Foundation
import Yosemite

/// View model for `RefundShippingLabelViewController` that provides data that are ready for display in the view.
struct RefundShippingLabelViewModel {
    let purchaseDate: String
    let refundableAmount: String
    let refundButtonTitle: String

    private let shippingLabel: ShippingLabel
    private let stores: StoresManager
    private let analytics: Analytics

    init(shippingLabel: ShippingLabel,
         currencyFormatter: CurrencyFormatter,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.purchaseDate = shippingLabel.dateCreated.toString(dateStyle: .medium, timeStyle: .short)
        self.refundableAmount = currencyFormatter.formatAmount(Decimal(shippingLabel.refundableAmount), with: shippingLabel.currency) ?? ""
        self.refundButtonTitle = String.localizedStringWithFormat(Localization.refundButtonTitleFormat, refundableAmount)
        self.shippingLabel = shippingLabel
        self.stores = stores
        self.analytics = analytics
    }

    /// Requests a refund for a shipping label remotely.
    func refundShippingLabel(completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void) {
        analytics.track(.shippingLabelRefundRequested)
        let action = ShippingLabelAction.refundShippingLabel(shippingLabel: shippingLabel) { result in
            completion(result)
        }
        stores.dispatch(action)
    }
}

extension RefundShippingLabelViewModel {
    enum Localization {
        static let refundButtonTitleFormat =
            NSLocalizedString("Refund Label (%1$@)",
                              comment: "Button title for requesting a refund for a shipping label. " +
                                "The variable is a formatted amount that is eligible for refund (e.g. $7.50).")
    }
}
