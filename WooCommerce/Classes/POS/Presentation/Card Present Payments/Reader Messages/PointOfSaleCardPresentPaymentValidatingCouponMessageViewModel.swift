import Foundation

struct PointOfSaleCardPresentPaymentValidatingCouponMessageViewModel: Equatable {
    let title: String = Localization.title
    let message: String = Localization.message
}

private extension PointOfSaleCardPresentPaymentValidatingCouponMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.validatingCoupon.title",
            value: "Getting ready",
            comment: "Title shown on the Point of Sale checkout while the order with coupons is being validated."
        )
        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.validatingCoupon.message",
            value: "Validating coupon",
            comment: "Message shown on the Point of Sale checkout while the order with coupons is being validated."
        )
    }
}
