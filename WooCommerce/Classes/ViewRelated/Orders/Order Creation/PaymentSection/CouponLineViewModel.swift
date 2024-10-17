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
                                                comment: "The singular coupon summary. Reads like: Coupon (code1)")
    }
}
