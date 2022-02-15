import SwiftUI

struct CouponUsageDetails: View {

    @ObservedObject private var viewModel: CouponDetailsViewModel

    init(viewModel: CouponDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

private extension CouponUsageDetails {
    enum Localization {
        static let usageRestriction = NSLocalizedString("Usage Restrictions", comment: "Title for the usage restrictions section on coupon usage details screen")
        static let minimumSpend = NSLocalizedString(
            "Minimum Spend (%1$@)",
            comment: "Title for the minimum spend row on coupon usage details screen with currency symbol within the brackets. " +
            "Reads like: Minimum Spend ($)"
        )
        static let maximumSpend = NSLocalizedString(
            "Maximum Spend (%1$@)",
            comment: "Title for the maximum spend row on coupon usage details screen with currency symbol within the brackets. " +
            "Reads like: Maximum Spend ($)"
        )
        static let usageLimitPerCoupon = NSLocalizedString(
            "Usage Limit Per Coupon",
            comment: "Title for the usage limit per coupon row in coupon usage details screen."
        )
        static let limitUsageToXItems = NSLocalizedString(
            "Limit Usage to X Items",
            comment: "Title for the limit usage to X items row in coupon usage details screen."
        )
        static let allowedEmails = NSLocalizedString(
            "Allowed Emails",
            comment: "Title for the allowed email row in coupon usage details screen."
        )
        static let usageLimits = NSLocalizedString("Usage Limits", comment: "Title for the usage limits section on coupon usage details screen")
        static let individualUseOnly = NSLocalizedString(
            "Individual Use Only",
            comment: "Title for the individual use only row in coupon usage details screen."
        )
        static let excludeSaleItems = NSLocalizedString(
            "Exclude Sale Items",
            comment: "Title for the exclude sale items row in coupon usage details screen."
        )
    }
}

#if DEBUG
struct CouponUsageDetails_Previews: PreviewProvider {
    static var previews: some View {
        CouponUsageDetails(viewModel: .init(coupon: .sampleCoupon))
    }
}
#endif
