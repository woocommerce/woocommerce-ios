import SwiftUI
import Yosemite

/// Hosting controller wrapper for `CouponDetails`
///
final class CouponDetailsHostingController: UIHostingController<CouponDetails> {

    init(viewModel: CouponDetailsViewModel) {
        super.init(rootView: CouponDetails(viewModel: viewModel))
        // The navigation title is set here instead of the SwiftUI view's `navigationTitle`
        // to avoid the blinking of the title label when pushed from UIKit view.
        title = viewModel.couponCode

        // Set presenting view controller to show the notice presenter here
        rootView.noticePresenter.presentingViewController = self
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct CouponDetails: View {
    @ObservedObject private var viewModel: CouponDetailsViewModel
    @State private var showingActionSheet: Bool = false
    @State private var showingShareSheet: Bool = false
    @State private var showingUsageDetails: Bool = false
    @State private var showingAmountLoadingErrorPrompt: Bool = false
    @State private var showingEnableAnalytics: Bool = false

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    /// The presenter to display notice when the coupon code is copied.
    /// It is kept internal so that the hosting controller can update its presenting controller to itself.
    let noticePresenter: DefaultNoticePresenter

    init(viewModel: CouponDetailsViewModel) {
        self.viewModel = viewModel
        self.noticePresenter = DefaultNoticePresenter()
        viewModel.syncCoupon()
        viewModel.loadCouponReport()

        ServiceLocator.analytics.track(.couponDetails, withProperties: ["action": "loaded"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Anchor the action sheet at the top to be able to show the popover on iPad in the most appropriate position
                    Divider()
                        .actionSheet(isPresented: $showingActionSheet) {
                            ActionSheet(
                                title: Text(Localization.manageCoupon),
                                buttons: [
                                    .default(Text(Localization.copyCode), action: {
                                        UIPasteboard.general.string = viewModel.couponCode
                                        let notice = Notice(title: Localization.couponCopied, feedbackType: .success)
                                        noticePresenter.enqueue(notice: notice)
                                        ServiceLocator.analytics.track(.couponDetails, withProperties: ["action": "copied_code"])
                                    }),
                                    .default(Text(Localization.shareCoupon), action: {
                                        showingShareSheet = true
                                        ServiceLocator.analytics.track(.couponDetails, withProperties: ["action": "shared_code"])
                                    }),
                                    .cancel()
                                ]
                            )
                        }
                        .shareSheet(isPresented: $showingShareSheet) {
                            ShareSheet(activityItems: [viewModel.shareMessage])
                        }

                    VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                        Text(viewModel.couponCode)
                            .font(.title2)
                            .bold()
                        StatusView(label: viewModel.expiryStatus,
                                   backgroundColor: viewModel.expiryStatusBackgroundColor)
                    }
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                    .padding(.horizontal, Constants.margin)
                    .padding(.vertical, Constants.summarySectionVerticalSpacing)

                    Divider()

                    summarySection
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Constants.margin)
                        .background(Color(.listForeground))

                    Divider()
                    Spacer().frame(height: Constants.margin)
                    Divider()

                    VStack(alignment: .leading, spacing: 0) {
                        Text(Localization.performance)
                            .bold()
                            .padding(Constants.margin)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(Localization.discountedOrders)
                                    .secondaryBodyStyle()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Constants.margin)
                                Spacer()
                                amountTitleView
                            }
                            HStack(alignment: .firstTextBaseline) {
                                Text(viewModel.discountedOrdersCount)
                                    .font(.title)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Constants.margin)
                                Spacer()
                                Group {
                                    if viewModel.shouldShowErrorLoadingAmount {
                                        Text(Localization.errorLoadingData)
                                            .secondaryBodyStyle()
                                    } else if let amount = viewModel.discountedAmount {
                                        Text(amount)
                                            .font(.title)
                                    } else {
                                        // Shimmering effect on mock data
                                        Text("$0.00")
                                            .font(.title)
                                            .redacted(reason: .placeholder)
                                            .shimmering()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Constants.margin)
                            }
                        }
                    }
                    .padding(.bottom, Constants.margin)
                    .background(Color(.listForeground))

                    Divider()
                }
                NavigationLink(destination: CouponUsageDetails(viewModel: .init(coupon: viewModel.coupon)), isActive: $showingUsageDetails) {
                    EmptyView()
                }.hidden()
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .sheet(isPresented: $showingEnableAnalytics) {
                EnableAnalyticsView(viewModel: .init(siteID: viewModel.siteID),
                                    presentingController: noticePresenter.presentingViewController,
                                    completionHandler: {
                    viewModel.loadCouponReport()
                })
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingActionSheet = true
                }, label: {
                    Image(uiImage: .moreImage)
                        .renderingMode(.template)
                })
            }
        }
        .wooNavigationBarStyle()
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Constants.summarySectionVerticalSpacing) {
            Text(Localization.summarySectionTitle)
                .bold()
                .padding(.top, Constants.margin)

            VStack(alignment: .leading, spacing: Constants.margin) {
                Text(Localization.description)
                    .secondaryBodyStyle()
                Text(viewModel.description.quoted)
            }
            .renderedIf(viewModel.description.isNotEmpty)

            VStack(alignment: .leading, spacing: Constants.summarySectionVerticalSpacing) {
                Text(viewModel.discountType)

                Text(viewModel.summary)

                Text(Localization.individualUse)
                    .renderedIf(viewModel.individualUseOnly)

                Text(Localization.allowsFreeShipping)
                    .renderedIf(viewModel.allowsFreeShipping)

                Text(Localization.excludesSaleItems)
                    .renderedIf(viewModel.excludeSaleItems)
            }

            VStack(alignment: .leading, spacing: Constants.summarySectionVerticalSpacing) {
                Text(String.localizedStringWithFormat(Localization.minimumSpend, viewModel.minimumAmount))
                    .renderedIf(viewModel.minimumAmount.isNotEmpty)

                Text(String.localizedStringWithFormat(Localization.maximumSpend, viewModel.maximumAmount))
                    .renderedIf(viewModel.maximumAmount.isNotEmpty)

                Text(String.localizedStringWithFormat(Localization.singularLimitPerUser, viewModel.usageLimitPerUser))
                    .renderedIf(viewModel.usageLimitPerUser == 1)

                Text(String.localizedStringWithFormat(Localization.pluralLimitPerUser, viewModel.usageLimitPerUser))
                    .renderedIf(viewModel.usageLimitPerUser > 1)
            }
            .renderedIf(viewModel.minimumAmount.isNotEmpty ||
                        viewModel.maximumAmount.isNotEmpty ||
                        viewModel.usageLimitPerUser > 0)

            Text(String.localizedStringWithFormat(Localization.expiryFormat, viewModel.expiryDate))
                .renderedIf(viewModel.expiryDate.isNotEmpty)

            Text(String.localizedStringWithFormat(Localization.emailRestriction, viewModel.emailRestrictions.joined(separator: ", ")))
                .renderedIf(viewModel.emailRestrictions.isNotEmpty)
        }
        .bodyStyle()
        .padding(.horizontal, Constants.margin)
    }

    @ViewBuilder
    private var amountTitleView: some View {
        Text(Localization.amount)
            .secondaryBodyStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.margin)
            .renderedIf(!viewModel.shouldShowErrorLoadingAmount)

        Button(action: showAmountLoadingErrorDetails) {
            HStack(spacing: Constants.errorIconHorizontalPadding) {
                Text(Localization.amount)
                    .secondaryBodyStyle()

                Image(uiImage: .infoImage)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundColor(viewModel.hasWCAnalyticsDisabled ?
                                     Color(UIColor.withColorStudio(.orange, shade: .shade30)) :
                                     Color(UIColor.error))
                    .frame(width: Constants.errorIconSize * scale,
                           height: Constants.errorIconSize * scale)
                    .actionSheet(isPresented: $showingAmountLoadingErrorPrompt) {
                        ActionSheet(
                            title: Text(Localization.errorLoadingAnalytics),
                            buttons: [
                                .default(Text(Localization.tryAgain), action: {
                                    viewModel.loadCouponReport()
                                }),
                                .cancel()
                            ]
                        )
                    }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Constants.margin)
        .renderedIf(viewModel.shouldShowErrorLoadingAmount)
    }

    private func showAmountLoadingErrorDetails() {
        if viewModel.hasWCAnalyticsDisabled {
            showingEnableAnalytics = true
        } else {
            showingAmountLoadingErrorPrompt = true
        }
    }
}

// MARK: - Subtypes
//
private extension CouponDetails {
    enum Constants {
        static let margin: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
        static let errorIconSize: CGFloat = 20
        static let errorIconHorizontalPadding: CGFloat = 4
        static let summarySectionVerticalSpacing: CGFloat = 24
    }

    enum Localization {
        static let summarySectionTitle = NSLocalizedString("Coupon Summary", comment: "Title of Summary section in Coupon Details screen")
        static let description = NSLocalizedString("Description", comment: "Title of the description field in Coupon Details screen")
        static let expiryFormat = NSLocalizedString(
            "Expires %1$@",
            comment: "Formatted content for coupon expiry date, reads like: Expires August 4, 2022"
        )
        static let allowsFreeShipping = NSLocalizedString(
            "Allows free shipping",
            comment: "Text on Coupon Details screen to indicate that the coupon allows free shipping"
        )
        static let excludesSaleItems = NSLocalizedString(
            "Excludes sale items",
            comment: "Text on Coupon Details screen to indicate that the coupon can not be applied to sale items"
        )
        static let individualUse = NSLocalizedString(
            "Individual use only",
            comment: "Text on Coupon Details screen to indicate that the coupon can not be applied in conjunction with other coupons"
        )
        static let minimumSpend = NSLocalizedString(
            "Minimum spend of %1$@",
            comment: "The minimum limit of spending required for a coupon on the Coupon Details screen, reads like: Minimum spend of $20.00"
        )
        static let maximumSpend = NSLocalizedString(
            "Maximum spend of %1$@",
            comment: "The maximum limit of spending allowed for a coupon on the Coupon Details screen, reads like: Minimum spend of $20.00"
        )
        static let singularLimitPerUser = NSLocalizedString(
            "%1$d use per user",
            comment: "The singular limit of time for each user to apply a coupon, reads like: 1 use per user"
        )
        static let pluralLimitPerUser = NSLocalizedString(
            "%1$d uses per user",
            comment: "The plural limit of time for each user to apply a coupon, reads like: 10 uses per user"
        )
        static let emailRestriction = NSLocalizedString(
            "Restricted to customers with emails: %1$@",
            comment: "Restriction for customers with specified emails to use a coupon, " +
            "reads like: Restricted to customers with emails: *@a8c.com, *@vip.com"
        )

        static let manageCoupon = NSLocalizedString("Manage Coupon", comment: "Title of the action sheet displayed from the Coupon Details screen")
        static let copyCode = NSLocalizedString("Copy Code", comment: "Action title for copying coupon code from the Coupon Details screen")
        static let couponCopied = NSLocalizedString("Coupon copied", comment: "Notice message displayed when a coupon code is " +
                                                    "copied from the Coupon Details screen")
        static let shareCoupon = NSLocalizedString("Share Coupon", comment: "Action title for sharing coupon from the Coupon Details screen")
        static let performance = NSLocalizedString("Performance", comment: "Title of the Performance section on Coupons Details screen")
        static let discountedOrders = NSLocalizedString("Discounted Orders", comment: "Title of the Discounted Orders label on Coupon Details screen")
        static let amount = NSLocalizedString("Amount", comment: "Title of the Amount label on Coupon Details screen")
        static let usageDetails = NSLocalizedString("Usage details", comment: "Title of the Usage details row in Coupon Details screen")
        static let errorLoadingData = NSLocalizedString(
            "Error loading data",
            comment: "Message displayed on Coupon Details screen when loading total discounted amount fails"
        )
        static let errorLoadingAnalytics = NSLocalizedString(
            "We encountered a problem loading analytics",
            comment: "Message displayed in the error prompt when loading total discounted amount in Coupon Details screen fails"
        )
        static let tryAgain = NSLocalizedString(
            "Try Again",
            comment: "Action displayed in the error prompt when loading total discounted amount in Coupon Details screen fails"
        )
    }

    struct DetailRow: Identifiable {
        var id: String { title }

        let title: String
        let content: String
        let action: () -> Void
    }
}

#if DEBUG
struct CouponDetails_Previews: PreviewProvider {
    static var previews: some View {
        CouponDetails(viewModel: CouponDetailsViewModel(coupon: Coupon.sampleCoupon))
    }
}
#endif
