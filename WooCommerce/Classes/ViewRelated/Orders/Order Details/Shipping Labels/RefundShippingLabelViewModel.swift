import Foundation
import struct Yosemite.ShippingLabel

/// View model for `RefundShippingLabelViewController` that provides data that are ready for display in the view.
struct RefundShippingLabelViewModel {
    let purchaseDate: String
    let refundableAmount: String
    let refundButtonTitle: String

    init(shippingLabel: ShippingLabel, currencyFormatter: CurrencyFormatter) {
        self.purchaseDate = shippingLabel.dateCreated.toString(dateStyle: .medium, timeStyle: .short)
        self.refundableAmount = currencyFormatter.formatAmount(Decimal(shippingLabel.refundableAmount), with: shippingLabel.currency) ?? ""
        self.refundButtonTitle = String.localizedStringWithFormat(Localization.refundButtonTitleFormat, refundableAmount)
    }
}

private extension RefundShippingLabelViewModel {
    enum Localization {
        static let refundButtonTitleFormat =
            NSLocalizedString("Refund Label (%1$@)",
                              comment: "Button title for requesting a refund for a shipping label. " +
                                "The variable is a formatted amount that is eligible for refund (e.g. $7.50).")
    }
}
