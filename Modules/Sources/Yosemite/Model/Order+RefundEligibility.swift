import Foundation

public enum OrderRefundEligibilityFailure: LocalizedError, Equatable {
    case giftCardUnsupported

    public var title: String {
        switch self {
        case .giftCardUnsupported:
            return NSLocalizedString(
                "orderDetails.issueRefund.giftCardUnsupported.alert.title",
                value: "Refund from your store admin",
                comment: "Title shown when a merchant tries to refund an order paid with a gift card"
            )
        }
    }

    public var errorDescription: String? {
        switch self {
        case .giftCardUnsupported:
            return NSLocalizedString(
                "orderDetails.issueRefund.giftCardUnsupported.alert.message",
                value: "This order was paid with a gift card. Refunding here won’t restore the gift-card balance. " +
                "To refund correctly, please process it from your store admin on the web.",
                comment: "Message explaining why an order paid with a gift card must be refunded from the store admin"
            )
        }
    }

    public var dismissButtonTitle: String {
        switch self {
        case .giftCardUnsupported:
            return NSLocalizedString(
                "orderDetails.issueRefund.giftCardUnsupported.alert.dismissButton",
                value: "OK",
                comment: "Button dismissing the error shown when a gift-card order cannot be refunded in the app"
            )
        }
    }
}

public extension Order {
    var refundEligibilityFailure: OrderRefundEligibilityFailure? {
        appliedGiftCards.isEmpty ? nil : .giftCardUnsupported
    }
}
