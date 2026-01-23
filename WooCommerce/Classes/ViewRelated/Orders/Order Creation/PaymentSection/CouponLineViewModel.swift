import Foundation

struct CouponLineViewModel {
    let code: String
    let discount: String

    var formattedTitle: String {
        String.localizedStringWithFormat(Localization.singularCoupon, code)
    }

    let detailsViewModel: CouponLineDetailsViewModel
}

private extension CouponLineViewModel {
    enum Localization {
        static let singularCoupon = NSLocalizedString("Coupon (%1$@)",
                                                comment: "This text appears as a label for a coupon line item in the order creation interface, displaying the coupon with its specific code in parentheses (e.g., 'Coupon (SAVE20)'). It's used to identify individual coupons applied to an order during the checkout or order management process.")
    }
}
