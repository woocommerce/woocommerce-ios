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

        // Set manually the edit coupon button click event to present
        // the AddEditCoupon view on top of the Coupon details
        rootView.onEditCoupon = { [weak self] addEditCouponViewModel in
            guard let self = self else { return }
            let addEditHostingController = AddEditCouponHostingController(
                viewModel: addEditCouponViewModel,
                onDisappear: {
                    viewModel.resetAddEditViewModel()
                })
            self.present(addEditHostingController, animated: true)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct CouponDetails: View {

    // Closure to be triggered when the edit coupon button is clicked
    var onEditCoupon: (AddEditCouponViewModel) -> Void

    @ObservedObject private var viewModel: CouponDetailsViewModel
    @State private var showingActionSheet: Bool = false
    @State private var showingShareSheet: Bool = false
    @State private var showingAmountLoadingErrorPrompt: Bool = false
    @State private var showingEnableAnalytics: Bool = false
    @State private var showingDeletionConfirmAlert: Bool = false

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    /// The presenter to display notice when the coupon code is copied.
    /// It is kept internal so that the hosting controller can update its presenting controller to itself.
    let noticePresenter: DefaultNoticePresenter

    init(viewModel: CouponDetailsViewModel,
         onEditCoupon: @escaping (AddEditCouponViewModel) -> Void = {_ in }) {
        self.viewModel = viewModel
        self.onEditCoupon = onEditCoupon
        self.noticePresenter = DefaultNoticePresenter()
        viewModel.syncCoupon()
        viewModel.loadCouponReport()

        ServiceLocator.analytics.track(.couponDetails, withProperties: ["action": "loaded"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                        Text(viewModel.couponCode)
                            .font(.title2)
                            .bold()
                        StatusView(label: viewModel.expiryStatus,
                                   foregroundColor: viewModel.expiryStatusForegroundColor,
                                   backgroundColor: viewModel.expiryStatusBackgroundColor)
                    }
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                    .padding(.horizontal, Constants.margin)
                    .padding(.vertical, Constants.summarySectionVerticalSpacing)

                    Text(viewModel.description)
                        .bold()
                        .footnoteStyle()
                        .renderedIf(viewModel.description.isNotEmpty)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .padding(.horizontal, Constants.margin)
                        .padding(.bottom, Constants.summarySectionVerticalSpacing)

                    Divider()

                    summarySection
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Constants.margin)
                        .background(Color(.listForeground(modal: false)))

                    Divider()
                    Spacer().frame(height: Constants.margin)
                    Divider()

                    VStack(alignment: .leading, spacing: 0) {
                        Text(Localization.performance)
                            .bold()
                            .padding(Constants.margin)
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
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                    .padding(.bottom, Constants.margin)
                    .background(Color(.listForeground(modal: false)))

                    Divider()
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal])
            .sheet(isPresented: $showingEnableAnalytics) {
                EnableAnalyticsView(viewModel: .init(siteID: viewModel.siteID),
                                    presentingController: noticePresenter.presentingViewController,
                                    completionHandler: {
                    viewModel.loadCouponReport()
                })
            }
            .alert(isPresented: $showingDeletionConfirmAlert, content: {
                Alert(title: Text(Localization.deleteCoupon),
                      message: Text(Localization.deleteCouponConfirm),
                      primaryButton: .destructive(Text(Localization.deleteButton), action: handleCouponDeletion),
                      secondaryButton: .cancel())
            })
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isDeletionInProgress {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    Button(action: {
                        showingActionSheet = true
                    }, label: {
                        Image(uiImage: .moreImage)
                            .renderingMode(.template)
                    })
                    .confirmationDialog(Localization.manageCoupon, isPresented: $showingActionSheet, actions: {
                        actionSheetContent
                    })
                }
            }
        }
        .navigationTitle(viewModel.coupon.code)
        .wooNavigationBarStyle()
        .shareSheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [viewModel.shareMessage])
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Constants.summarySectionVerticalSpacing) {
            Text(Localization.summarySectionTitle)
                .bold()
                .padding(.top, Constants.margin)

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

                Text(String.pluralize(Int(viewModel.usageLimit),
                                      singular: Localization.singularUsageLimitPerCoupon,
                                      plural: Localization.pluralUsageLimitPerCoupon))
                .renderedIf(viewModel.usageLimit > 0)

                Text(String.pluralize(Int(viewModel.usageLimitPerUser),
                                      singular: Localization.singularLimitPerUser,
                                      plural: Localization.pluralLimitPerUser))
                .renderedIf(viewModel.usageLimitPerUser > 0)

                Text(String.pluralize(Int(viewModel.limitUsageToXItems),
                                      singular: Localization.singularItemsInCartUsageLimit,
                                      plural: Localization.pluralItemsInCartUsageLimit))
                .renderedIf(viewModel.shouldDisplayLimitUsageToXItems)
            }
            .renderedIf(viewModel.minimumAmount.isNotEmpty ||
                        viewModel.maximumAmount.isNotEmpty ||
                        viewModel.usageLimit > 0 ||
                        viewModel.usageLimitPerUser > 0 ||
                        viewModel.limitUsageToXItems > 0)

            Text(String.localizedStringWithFormat(Localization.expiryFormat, viewModel.expiryDate))
                .renderedIf(viewModel.expiryDate.isNotEmpty)

            Text(String.localizedStringWithFormat(Localization.emailRestriction, viewModel.emailRestrictions.joined(separator: ", ")))
                .renderedIf(viewModel.emailRestrictions.isNotEmpty)
        }
        .bodyStyle()
        .padding(.horizontal, Constants.margin)
    }

    @ViewBuilder
    private var actionSheetContent: some View {
        Button(Localization.copyCode) {
            UIPasteboard.general.string = viewModel.couponCode
            let notice = Notice(title: Localization.couponCopied, feedbackType: .success)
            noticePresenter.enqueue(notice: notice)
            ServiceLocator.analytics.track(.couponDetails, withProperties: ["action": "copied_code"])
        }

        Button(Localization.shareCoupon) {
            showingShareSheet = true
            ServiceLocator.analytics.track(.couponDetails, withProperties: ["action": "shared_code"])
        }

        if viewModel.isEditingEnabled {
            Button(Localization.editCoupon) {
                ServiceLocator.analytics.track(.couponDetails, withProperties: ["action": "tapped_edit"])
                onEditCoupon(viewModel.addEditCouponViewModel)
            }
        }

        Button(Localization.deleteCoupon, role: .destructive) {
            ServiceLocator.analytics.track(.couponDetails, withProperties: ["action": "tapped_delete"])
            showingDeletionConfirmAlert = true
        }
        .tint(Color(.error))
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

    private func handleCouponDeletion() {
        viewModel.deleteCoupon(onSuccess: viewModel.onDeletion, onFailure: {
            let notice = Notice(title: Localization.errorDeletingCoupon, feedbackType: .error)
            noticePresenter.enqueue(notice: notice)
        })
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
        static let singularItemsInCartUsageLimit = NSLocalizedString(
                "Limited to %1$d item in cart",
                comment: "The required number of items in the cart to apply a coupon in singular form, reads like: " +
                        "Limited to 1 item in cart"
        )
        static let pluralItemsInCartUsageLimit = NSLocalizedString(
                "Limited to %1$d items in cart",
                comment: "The required number of items in the cart to apply a coupon in plural form, reads like: " +
                        "Limited to 10 items in cart"
        )
        static let singularUsageLimitPerCoupon = NSLocalizedString(
                "Can be used %1$d time",
                comment: "The singular total limit where the same coupon can be applied for everyone, " +
                        "reads like: Can be used 1 time"
        )
        static let pluralUsageLimitPerCoupon = NSLocalizedString(
                "Can be used %1$d times",
                comment: "The plural total limit where the same coupon can be applied for everyone, " +
                        "reads like: Can be used 10 times"
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
        static let editCoupon = NSLocalizedString("Edit Coupon", comment: "Action title for editing a coupon from the Coupon Details screen")
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
        static let deleteCoupon = NSLocalizedString("Delete Coupon", comment: "Action title for deleting coupon on the Coupon Details screen")
        static let deleteCouponConfirm = NSLocalizedString(
            "Are you sure you want to delete this coupon?",
            comment: "Confirm message for deleting coupon on the Coupon Details screen"
        )
        static let deleteButton = NSLocalizedString(
            "Delete",
            comment: "Title for the action button on the confirm alert for deleting coupon on the Coupon Details screen"
        )
        static let errorDeletingCoupon = NSLocalizedString(
            "Failed to delete coupon. Please try again.",
            comment: "Error message on the Coupon Details screen when deleting coupon fails"
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
