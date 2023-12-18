import SwiftUI

struct AddOrderComponentsSection: View {
    /// View model to drive the view content
    let viewModel: EditableOrderViewModel.PaymentDataViewModel

    /// Indicates if the coupon line details screen should be shown or not.
    ///
    @State private var shouldShowAddCouponLineDetails: Bool = false

    /// Indicates if the gift card code input sheet should be shown or not.
    ///
    @Binding private var shouldShowGiftCardForm: Bool

    /// Indicates if the coupons informational tooltip should be shown or not.
    ///
    @Binding private var shouldShowCouponsInfoTooltip: Bool

    /// Indicates if the go to coupons alert should be shown or not.
    ///
    @State private var shouldShowGoToCouponsAlert: Bool = false

    /// Indicates if the shipping line details screen should be shown or not.
    ///
    @Binding private var shouldShowShippingLineDetails: Bool

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: EditableOrderViewModel.PaymentDataViewModel,
         shouldShowCouponsInfoTooltip: Binding<Bool>,
         shouldShowShippingLineDetails: Binding<Bool>,
         shouldShowGiftCardForm: Binding<Bool>) {
        self.viewModel = viewModel
        self._shouldShowCouponsInfoTooltip = shouldShowCouponsInfoTooltip
        self._shouldShowShippingLineDetails = shouldShowShippingLineDetails
        self._shouldShowGiftCardForm = shouldShowGiftCardForm
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            // "Add order components" rows
            Group {
                Divider()
                    .padding(.leading, Constants.dividerLeadingPadding)

                addShippingRow

                addCouponRow

                addGiftCardRow
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
    }
}

private extension AddOrderComponentsSection {
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
                    .accessibilityLabel(Localization.couponTooltipInformationAccessibilityLabel)
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
    }

    @ViewBuilder var addShippingRow: some View {
        Button(Localization.addShipping) {
            shouldShowShippingLineDetails = true
        }
        .buttonStyle(PlusButtonStyle())
        .padding()
        .accessibilityIdentifier("add-shipping-button")
        .disabled(viewModel.orderIsEmpty)
        .renderedIf(!viewModel.shouldShowShippingTotal)
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
        .renderedIf(viewModel.isGiftCardEnabled && viewModel.giftCardToApply.isNilOrEmpty)
        .sheet(isPresented: $shouldShowGiftCardForm) {
            giftCardInput
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
}

// MARK: Constants
private extension AddOrderComponentsSection {
    enum Localization {
        static let addCoupon = NSLocalizedString(
            "order.form.coupon.add.button.title",
            value: "Add Coupon",
            comment: "Title for the Coupon screen during order creation")

        static let addShipping = NSLocalizedString(
            "order.form.shipping.add.button.title",
            value: "Add Shipping",
            comment: "Title text of the button that adds shipping line when creating a new order")

        static let addGiftCard = NSLocalizedString(
            "order.form.giftCard.add.button.title",
            value: "Add Gift Card",
            comment: "Title text of the button that adds shipping line when creating a new order")

        static let couponsTooltipTitle = NSLocalizedString(
            "order.form.coupon.unavailable.tooltip.title",
            value: "Coupons unavailable",
            comment: "Title text for the coupons row informational tooltip")

        static let couponsTooltipDescription = NSLocalizedString(
            "order.form.coupon.unavailable.tooltip.description",
            value: "To add Coupons, please remove your Product Discounts",
            comment: "Description text for the coupons row informational tooltip")

        static let cancelButton = NSLocalizedString(
            "order.form.coupon.cancel.button.title",
            value: "Cancel",
            comment: "Cancel button title when showing the coupon list selector")

        static let goToCoupons = NSLocalizedString(
            "order.form.coupon.empty.goToCoupons.button.title",
            value: "Go to Coupons",
            comment: "Button title on the Coupon screen empty state when adding coupons to a new order. " +
            "The button navigates to the Coupons Section")

        static let goToCouponsAlertMessage = NSLocalizedString(
            "order.form.coupon.empty.goToCoupons.alert.message",
            value: "Do you want to navigate to the Coupons Menu? These changes will be discarded.",
            comment: "Confirm message for navigating to coupons when creating a new order")

        static let goToCouponsAlertButtonTitle = NSLocalizedString(
            "order.form.coupon.empty.goToCoupons.alert.confirm.button.title",
            value: "Go",
            comment: "Confirm button title for navigating to coupons when creating a new order")

        static let couponTooltipInformationAccessibilityLabel = NSLocalizedString(
            "order.form.coupon.moreInfo.accessibilityLabel",
            value: "Coupon information",
            comment: "An accessibility label for a More info button, rendered as a question mark icon, which shows coupon information.")

    }

    enum Constants {
        static let emptyOrderTitleVerticalPadding: CGFloat = 8
        static let emptyOrderTitleLockImageTrailingPadding: CGFloat = 16
        static let giftCardsSectionVerticalSpacing: CGFloat = 8
        static let taxesSectionVerticalSpacing: CGFloat = 8
        static let taxRateAddedAutomaticallyRowHorizontalSpacing: CGFloat = 8
        static let taxesAdaptativeStacksSpacing: CGFloat = 4
        static let sectionPadding: CGFloat = 16
        static let rowMinHeight: CGFloat = 44
        static let infoTooltipCornerRadius: CGFloat = 4
        static let dividerLeadingPadding: CGFloat = 16
        static let orderTotalBottomPadding: CGFloat = 8
    }
}

struct AddOrderComponentsSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00", orderTotal: "20.00")

        AddOrderComponentsSection(viewModel: viewModel,
                                  shouldShowCouponsInfoTooltip: .constant(true),
                                  shouldShowShippingLineDetails: .constant(false),
                                  shouldShowGiftCardForm: .constant(false))
            .previewLayout(.sizeThatFits)
    }
}
