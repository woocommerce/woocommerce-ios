import Foundation
import Yosemite

enum OrderRefundEligibilityFailure: LocalizedError, Equatable {
    case giftCardUnsupported

    var errorDescription: String? {
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
}

extension Order {
    var refundEligibilityFailure: OrderRefundEligibilityFailure? {
        appliedGiftCards.isEmpty ? nil : .giftCardUnsupported
    }
}
