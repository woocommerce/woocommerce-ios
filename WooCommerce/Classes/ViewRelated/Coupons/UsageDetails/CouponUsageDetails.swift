import SwiftUI

struct CouponUsageDetails: View {

    @ObservedObject private var viewModel: CouponUsageDetailsViewModel

    init(viewModel: CouponUsageDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ListHeaderView(text: Localization.usageRestriction.uppercased(), alignment: .left)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                        TitleAndTextFieldRow(title: String.localizedStringWithFormat(Localization.minimumSpend, viewModel.currencySymbol),
                                             placeholder: Localization.none,
                                             text: $viewModel.minimumSpend,
                                             editable: false,
                                             keyboardType: .decimalPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndTextFieldRow(title: String.localizedStringWithFormat(Localization.maximumSpend, viewModel.currencySymbol),
                                             placeholder: Localization.none,
                                             text: $viewModel.maximumSpend,
                                             editable: false,
                                             keyboardType: .decimalPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndTextFieldRow(title: Localization.usageLimitPerCoupon,
                                             placeholder: Localization.unlimited,
                                             text: $viewModel.usageLimitPerCoupon,
                                             editable: false,
                                             keyboardType: .asciiCapableNumberPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndTextFieldRow(title: Localization.usageLimitPerUser,
                                             placeholder: Localization.unlimited,
                                             text: $viewModel.usageLimitPerUser,
                                             editable: false,
                                             keyboardType: .asciiCapableNumberPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                    }
                    .background(Color(.listForeground))
                    .padding(.bottom, Constants.margin)

                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                        TitleAndTextFieldRow(title: Localization.limitUsageToXItems,
                                             placeholder: Localization.allQualifyingInCart,
                                             text: $viewModel.limitUsageToXItems,
                                             editable: false,
                                             keyboardType: .asciiCapableNumberPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndValueRow(title: Localization.allowedEmails,
                                         value: viewModel.allowedEmails.isNotEmpty ?
                                            .content(viewModel.allowedEmails) :
                                            .content(Localization.noRestrictions))
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                    }
                    .background(Color(.listForeground))
                    .padding(.top, Constants.margin)

                    ListHeaderView(text: Localization.usageLimits.uppercased(), alignment: .left)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                        TitleAndValueRow(title: Localization.individualUseOnly,
                                         value: .content(viewModel.individualUseOnly ? Localization.yes : Localization.no))
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                            .padding(.vertical, Constants.verticalSpacing)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndValueRow(title: Localization.excludeSaleItems,
                                         value: .content(viewModel.excludeSaleItems ? Localization.yes : Localization.no))
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                            .padding(.vertical, Constants.verticalSpacing)
                        Divider()
                    }
                    .background(Color(.listForeground))
                    .padding(.bottom, Constants.margin)
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal])
        }
        .navigationTitle(Localization.usageDetails)
    }
}

private extension CouponUsageDetails {
    enum Constants {
        static let margin: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
    }

    enum Localization {
        static let usageDetails = NSLocalizedString("Usage Details", comment: "Navigation title for usage details screen")
        static let usageRestriction = NSLocalizedString(
            "Usage Restrictions",
            comment: "Title for the usage restrictions section on coupon usage details screen"
        )
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
        static let usageLimitPerUser = NSLocalizedString(
            "Usage Limit Per User",
            comment: "Title for the usage limit per user row in coupon usage details screen."
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
        static let none = NSLocalizedString("None", comment: "Value for fields in Coupon Usage Details screen when no value is set")
        static let unlimited = NSLocalizedString("Unlimited", comment: "Value for fields in Coupon Usage Details screen when no limit is set")
        static let allQualifyingInCart = NSLocalizedString(
            "All Qualifying in Cart",
            comment: "Value for the limit usage to X items row in Coupon Usage Details screen when no limit is set"
        )
        static let noRestrictions = NSLocalizedString(
            "No Restrictions",
            comment: "Value for the allowed emails row in Coupon Usage Details screen when no restriction is set"
        )
        static let yes = NSLocalizedString(
            "Yes",
            comment: "Value for the individual use only row or the exclude sale items row in Coupon Usage Details screen when the value is true"
        )
        static let no = NSLocalizedString(
            "No",
            comment: "Value for the individual use only row or the exclude sale items row in Coupon Usage Details screen when the value is false"
        )
    }
}

#if DEBUG
struct CouponUsageDetails_Previews: PreviewProvider {
    static var previews: some View {
        CouponUsageDetails(viewModel: .init(coupon: .sampleCoupon))

        CouponUsageDetails(viewModel: .init(coupon: .sampleCoupon))
            .previewLayout(.fixed(width: 715, height: 320))
    }
}
#endif
