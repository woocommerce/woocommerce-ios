import SwiftUI
import WooFoundation

/// Represents the Payment section in an order
///
struct OrderPaymentSection: View {
    /// View model to drive the view content
    let viewModel: EditableOrderViewModel.PaymentDataViewModel

    /// Indicates if the shipping line details screen should be shown or not.
    ///
    @State private var shouldShowShippingLineDetails: Bool = false

    /// Indicates if the fee line details screen should be shown or not.
    ///
    @State private var shouldShowFeeLineDetails: Bool = false

    /// Indicates if the coupon line details screen should be shown or not.
    ///
    @State private var shouldShowAddCouponLineDetails: Bool = false

    /// Indicates if the go to coupons alert should be shown or not.
    ///
    @State private var shouldShowGoToCouponsAlert: Bool = false

    /// Indicates if the gift card code input sheet should be shown or not.
    ///
    @State private var shouldShowGiftCardForm: Bool = false

    /// Indicates if the tax educational dialog should be shown or not.
    ///
    @State private var shouldShowTaxEducationalDialog: Bool = false

    /// Keeps track of the selected coupon line details view model.
    ///
    @State private var selectedCouponLineDetailsViewModel: CouponLineDetailsViewModel? = nil

    /// Indicates if the coupons informational tooltip should be shown or not.
    ///
    @Binding private var shouldShowCouponsInfoTooltip: Bool

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: EditableOrderViewModel.PaymentDataViewModel, shouldShowCouponsInfoTooltip: Binding<Bool>) {
        self.viewModel = viewModel
        self._shouldShowCouponsInfoTooltip = shouldShowCouponsInfoTooltip
    }

    var body: some View {
        Divider()

        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text(Localization.payment)
                    .accessibilityAddTraits(.isHeader)
                    .headlineStyle()

                Spacer()

                Image(uiImage: .lockImage)
                    .foregroundColor(Color(.brand))
                    .renderedIf(viewModel.showNonEditableIndicators)

                ProgressView()
                    .renderedIf(viewModel.isLoading)
            }
            .padding()

            TitleAndValueRow(title: Localization.productsTotal, value: .content(viewModel.itemsTotal), selectionStyle: .none) {}

            shippingRow
                .sheet(isPresented: $shouldShowShippingLineDetails) {
                    ShippingLineDetails(viewModel: viewModel.shippingLineViewModel)
                }
            feesRow
                .sheet(isPresented: $shouldShowFeeLineDetails) {
                    FeeOrDiscountLineDetailsView(viewModel: viewModel.feeLineViewModel)
                }

            VStack {
                ForEach(viewModel.couponLineViewModels, id: \.title) { viewModel in
                    TitleAndValueRow(title: viewModel.title, value: .content(viewModel.discount), selectionStyle: .highlight) {
                        selectedCouponLineDetailsViewModel = viewModel.detailsViewModel
                    }
                }
            }
            .sheet(item: $selectedCouponLineDetailsViewModel) { viewModel in
                CouponLineDetails(viewModel: viewModel)
            }

            addCouponRow
            // The use of zIndex is necessary in order to display the view overlay from the Coupon row correctly on top of the section,
            // since this is build by multiple views. Otherwise we may see glitches in the UI when toggling the overlay.
                .zIndex(1)
                .sheet(isPresented: $shouldShowAddCouponLineDetails) {
                    NavigationView {
                        CouponListView(siteID: viewModel.siteID,
                                       emptyStateActionTitle: Localization.goToCoupons,
                                       emptyStateAction: {
                            shouldShowGoToCouponsAlert = true
                        },
                                       onCouponSelected: { coupon in
                            viewModel.addNewCouponLineClosure(coupon)
                            shouldShowAddCouponLineDetails = false
                        })
                        .navigationTitle(Localization.addCoupon)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(Localization.cancelButton) {
                                    shouldShowAddCouponLineDetails = false
                                }
                            }
                        }
                        .alert(isPresented: $shouldShowGoToCouponsAlert, content: {
                            Alert(title: Text(Localization.goToCoupons),
                                  message: Text(Localization.goToCouponsAlertMessage),
                                  primaryButton: .default(Text(Localization.goToCouponsAlertButtonTitle), action: {
                                viewModel.onGoToCouponsClosure()
                                MainTabBarController.presentCoupons()
                            }),
                                  secondaryButton: .cancel())
                        })
                    }
                }

            if viewModel.isGiftCardEnabled {
                if let giftCard = viewModel.giftCardToApply, giftCard.isNotEmpty {
                    editGiftCardRow(giftCard: giftCard)
                } else {
                    addGiftCardRow
                }
            }

            appliedGiftCardsSection

            taxesSection
                .fullScreenCover(isPresented: $shouldShowTaxEducationalDialog) {
                    TaxEducationalDialogView(viewModel: viewModel.taxEducationalDialogViewModel,
                                             onDismissWpAdminWebView: viewModel.onDismissWpAdminWebViewClosure)
                    .background(FullScreenCoverClearBackgroundView())
                }

            VStack(alignment: .leading, spacing: .zero) {
                TitleAndValueRow(title: Localization.discountTotal, value: .content(viewModel.discountTotal))
                    .renderedIf(viewModel.shouldShowDiscountTotal)

                TitleAndValueRow(title: Localization.orderTotal, value: .content(viewModel.orderTotal), bold: true, selectionStyle: .none) {}
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground(modal: true)))

        Divider()

        taxRateAddedAutomaticallyRow
            .renderedIf(viewModel.shouldShowStoredTaxRateAddedAutomatically)
    }
}

private extension OrderPaymentSection {
    @ViewBuilder var addCouponRow: some View {
        HStack(spacing: 0) {
            Button(Localization.addCoupon) {
                shouldShowAddCouponLineDetails = true
            }
            .buttonStyle(PlusButtonStyle())
            .disabled(viewModel.shouldDisableAddingCoupons)
            Button() {
                shouldShowCouponsInfoTooltip.toggle()
            } label: {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .frame(width: Constants.sectionPadding, height: Constants.sectionPadding)
            }
            .renderedIf(viewModel.shouldRenderCouponsInfoTooltip)
        }
        .padding()
        .accessibilityIdentifier("add-coupon-button")
        .overlay {
            TooltipView(toolTipTitle: Localization.couponsTooltipTitle,
                        toolTipDescription: Localization.couponsTooltipDescription,
                        offset: CGSize(width: 0, height: (Constants.rowMinHeight * scale) + Constants.sectionPadding),
                        safeAreaInsets: EdgeInsets())
            .padding()
            .renderedIf(shouldShowCouponsInfoTooltip)
        }
    }

    @ViewBuilder var shippingRow: some View {
        if viewModel.shouldShowShippingTotal {
            TitleAndValueRow(title: Localization.shippingTotal, value: .content(viewModel.shippingTotal), selectionStyle: .highlight) {
                shouldShowShippingLineDetails = true
            }
        } else {
            Button(Localization.addShipping) {
                shouldShowShippingLineDetails = true
            }
            .buttonStyle(PlusButtonStyle())
            .padding()
            .accessibilityIdentifier("add-shipping-button")
        }
    }

    @ViewBuilder var feesRow: some View {
        if viewModel.shouldShowFees {
            TitleAndValueRow(title: Localization.feesTotal, value: .content(viewModel.feesTotal), selectionStyle: .highlight) {
                shouldShowFeeLineDetails = true
            }
        } else {
            Button(Localization.addFee) {
                shouldShowFeeLineDetails = true
            }
            .buttonStyle(PlusButtonStyle())
            .padding()
            .accessibilityIdentifier("add-fee-button")
        }
    }

    @ViewBuilder var addGiftCardRow: some View {
        Button(Localization.addGiftCard) {
            shouldShowGiftCardForm = true
            viewModel.addGiftCardClosure()
        }
        .buttonStyle(PlusButtonStyle())
        .padding()
        .accessibilityIdentifier("add-gift-card-button")
        .disabled(!viewModel.isAddGiftCardActionEnabled)
        .sheet(isPresented: $shouldShowGiftCardForm) {
            giftCardInput
        }
    }

    @ViewBuilder func editGiftCardRow(giftCard: String) -> some View {
        HStack {
            Button {
                shouldShowGiftCardForm = true
            } label: {
                OrderFormGiftCardRow(code: giftCard)
            }
            .padding()
            .sheet(isPresented: $shouldShowGiftCardForm) {
                giftCardInput
            }
        }
    }

    @ViewBuilder var giftCardInput: some View {
        GiftCardInputView(viewModel: .init(code: viewModel.giftCardToApply ?? "",
                                           setGiftCard: { code in
            viewModel.setGiftCardClosure(code)
            shouldShowGiftCardForm = false
        }, dismiss: {
            shouldShowGiftCardForm = false
        }))
    }

    @ViewBuilder var appliedGiftCardsSection: some View {
        VStack(alignment: .leading, spacing: Constants.giftCardsSectionVerticalSpacing) {
            ForEach(viewModel.appliedGiftCards, id: \.self) { giftCard in
                TitleAndValueRow(title: giftCard.code, value: .content(giftCard.amount), selectionStyle: .none)
            }
        }
        .renderedIf(viewModel.appliedGiftCards.isNotEmpty)
    }

    @ViewBuilder var taxesSection: some View {
        VStack(alignment: .leading, spacing: Constants.taxesSectionVerticalSpacing) {
            taxSectionTitle
            taxLines
            taxBasedOnLine
            .renderedIf(viewModel.taxLineViewModels.isNotEmpty && viewModel.taxBasedOnSetting != nil)
        }
        .padding(Constants.sectionPadding)
    }

    @ViewBuilder var taxSectionTitle: some View {
        AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.taxesAdaptativeStacksSpacing) {
            Text(Localization.taxesTotal)
                .bodyStyle()

            Button {
                shouldShowTaxEducationalDialog = true
                viewModel.onTaxHelpButtonTappedClosure()
            } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(Color(.wooCommercePurple(.shade60)))
            }
            .renderedIf(viewModel.shouldShowTaxesInfoButton)

            Spacer()

            Text(viewModel.taxesTotal)
                .bodyStyle()
                .frame(width: nil, alignment: .trailing)
        }
    }

    @ViewBuilder var taxLines: some View {
        ForEach(viewModel.taxLineViewModels, id: \.title) { viewModel in
            HStack {
                AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.taxesAdaptativeStacksSpacing) {
                    Text(viewModel.title)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(viewModel.value)
                        .footnoteStyle()
                        .multilineTextAlignment(.trailing)
                        .frame(width: nil, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder var taxBasedOnLine: some View {
        Text(viewModel.taxBasedOnSetting?.displayString ?? "")
            .footnoteStyle()
            .multilineTextAlignment(.leading)
    }

    @ViewBuilder var taxRateAddedAutomaticallyRow: some View {
        VStack {
            HStack(alignment: .top, spacing: Constants.taxRateAddedAutomaticallyRowHorizontalSpacing) {
                Image(systemName: "info.circle")
                    .foregroundColor(Color(.wooCommercePurple(.shade60)))
                Text(Localization.taxRateAddedAutomaticallyRowText)
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .frame(minHeight: Constants.rowMinHeight)

            Divider()
        }
        .background(Color(.listForeground(modal: true)))
    }
}

// MARK: Constants
private extension OrderPaymentSection {
    enum Localization {
        static let payment = NSLocalizedString("Payment", comment: "Title text of the section that shows Payment details when creating a new order")
        static let productsTotal = NSLocalizedString("Products Total", comment: "Label for the row showing the total cost of products in the order")
        static let orderTotal = NSLocalizedString("Order Total", comment: "Label for the the row showing the total cost of the order")
        static let discountTotal = NSLocalizedString("Discount Total", comment: "Label for the the row showing the total discount of the order")
        static let addShipping = NSLocalizedString("Add Shipping", comment: "Title text of the button that adds shipping line when creating a new order")
        static let shippingTotal = NSLocalizedString("Shipping", comment: "Label for the row showing the cost of shipping in the order")
        static let addGiftCard = NSLocalizedString("Add Gift Card", comment: "Title text of the button that adds shipping line when creating a new order")
        static let addFee = NSLocalizedString("Add Fee", comment: "Title text of the button that adds a fee when creating a new order")
        static let feesTotal = NSLocalizedString("Fees", comment: "Label for the row showing the cost of fees in the order")
        static let taxes = NSLocalizedString("Taxes", comment: "Label for the row showing the taxes in the order")
        static let taxesTotal = NSLocalizedString("Taxes Total", comment: "Label for the title row showing the taxes in the order")
        static let addCoupon = NSLocalizedString("Add Coupon", comment: "Title for the Coupon screen during order creation")
        static let coupon = NSLocalizedString("Coupon", comment: "Label for the row showing the cost of coupon in the order")
        static let goToCoupons = NSLocalizedString("Go to Coupons", comment: "Button title on the Coupon screen empty state" +
                                                   "when creating a new order that navigates to the Coupons Section")
        static let goToCouponsAlertMessage = NSLocalizedString("Do you want to navigate to the Coupons Menu? These changes will be discarded.",
                                                               comment: "Confirm message for navigating to coupons when creating a new order")
        static let goToCouponsAlertButtonTitle = NSLocalizedString("Go", comment: "Confirm button title for navigating to coupons when creating a new order")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title when showing the coupon list selector")
        static let taxRateAddedAutomaticallyRowText = NSLocalizedString("Tax rate location added automatically",
                                                                        comment: "Notice in editable order details when the tax rate was added to the order")
        static let couponsTooltipTitle = NSLocalizedString(
            "Coupons unavailable",
            comment: "Title text for the coupons row informational tooltip")
        static let couponsTooltipDescription = NSLocalizedString(
            "To add Coupons, please remove your Product Discounts",
            comment: "Description text for the coupons row informational tooltip")
    }

    enum Constants {
        static let giftCardsSectionVerticalSpacing: CGFloat = 8
        static let taxesSectionVerticalSpacing: CGFloat = 8
        static let taxRateAddedAutomaticallyRowHorizontalSpacing: CGFloat = 8
        static let taxesAdaptativeStacksSpacing: CGFloat = 4
        static let sectionPadding: CGFloat = 16
        static let rowMinHeight: CGFloat = 44
        static let infoTooltipCornerRadius: CGFloat = 4
    }
}

struct OrderPaymentSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00", orderTotal: "20.00")

        OrderPaymentSection(viewModel: viewModel,
                            shouldShowCouponsInfoTooltip: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}
