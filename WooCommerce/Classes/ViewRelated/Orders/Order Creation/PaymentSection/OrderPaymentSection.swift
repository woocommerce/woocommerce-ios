import SwiftUI
import WooFoundation

/// Represents the Payment section in an order
///
struct OrderPaymentSection: View {
    /// View model to drive the view content
    let viewModel: EditableOrderViewModel.PaymentDataViewModel

    /// Indicates if the shipping line details screen should be shown or not.
    ///
    @Binding private var shouldShowShippingLineDetails: Bool

    /// Indicates if the gift card code input sheet should be shown or not.
    ///
    @Binding private var shouldShowGiftCardForm: Bool

    /// Indicates if the tax educational dialog should be shown or not.
    ///
    @State private var shouldShowTaxEducationalDialog: Bool = false

    /// Keeps track of the selected coupon line details view model.
    ///
    @State private var selectedCouponLineDetailsViewModel: CouponLineDetailsViewModel? = nil

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var giftCard: String? {
        guard let giftCard = viewModel.giftCardToApply,
              giftCard.isNotEmpty else {
            return nil
        }

        return giftCard
    }

    init(viewModel: EditableOrderViewModel.PaymentDataViewModel,
         shouldShowShippingLineDetails: Binding<Bool>,
         shouldShowGiftCardForm: Binding<Bool>) {
        self.viewModel = viewModel
        self._shouldShowShippingLineDetails = shouldShowShippingLineDetails
        self._shouldShowGiftCardForm = shouldShowGiftCardForm
    }

    var body: some View {
        Divider()

        VStack(alignment: .leading, spacing: .zero) {
            // Titles (not coincident)
            orderWithItemsTitle
            emptyOrderTitle

            // Order components
            Group {
                productsRow

                customAmountsRow

                existingShippingRow

                appliedCouponsRows

                giftCardsSection

                taxesSection
            }

            // Totals
            Group {
                discountsTotalRow

                orderTotalRow
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground(modal: true)))
        .sheet(isPresented: $shouldShowShippingLineDetails) {
            ShippingLineDetails(viewModel: viewModel.shippingLineViewModel)
        }

        taxRateAddedAutomaticallyRow
            .renderedIf(viewModel.shouldShowStoredTaxRateAddedAutomatically)
    }
}

private extension OrderPaymentSection {
    @ViewBuilder var emptyOrderTitle: some View {
        HStack {
            TitleAndValueRow(title: Localization.orderTotal, value: .content(viewModel.orderTotal), bold: true, selectionStyle: .none) {}
                .padding(.vertical, Constants.emptyOrderTitleVerticalPadding)

            Image(uiImage: .lockImage)
                .foregroundColor(Color(.brand))
                .padding(.trailing, Constants.emptyOrderTitleLockImageTrailingPadding)
                .renderedIf(viewModel.showNonEditableIndicators)

        }
        .padding(.horizontal, insets: safeAreaInsets)
        .renderedIf(viewModel.orderIsEmpty)
    }

    @ViewBuilder var orderWithItemsTitle: some View {
        HStack {
            Text(Localization.paymentTotals)
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
        .renderedIf(!viewModel.orderIsEmpty)
    }

    @ViewBuilder var appliedCouponsRows: some View {
        VStack {
            ForEach(viewModel.couponLineViewModels, id: \.title) { viewModel in
                TitleAndValueRow(title: viewModel.title,
                                 titleSuffixImage: rowsEditImage,
                                 value: .content(viewModel.discount),
                                 selectionStyle: editableRowsSelectionStyle) {
                    selectedCouponLineDetailsViewModel = viewModel.detailsViewModel
                }
            }
        }
        .sheet(item: $selectedCouponLineDetailsViewModel) { viewModel in
            CouponLineDetails(viewModel: viewModel)
        }
    }

    @ViewBuilder var existingShippingRow: some View {
        TitleAndValueRow(title: Localization.shippingTotal,
                         titleSuffixImage: rowsEditImage,
                         value: .content(viewModel.shippingTotal),
                         selectionStyle: editableRowsSelectionStyle) {
            shouldShowShippingLineDetails = true
        }
        .renderedIf(viewModel.shouldShowShippingTotal)
    }

    @ViewBuilder var productsRow: some View {
        TitleAndValueRow(title: Localization.productsTotal, value: .content(viewModel.itemsTotal), selectionStyle: .none) {}
            .renderedIf(viewModel.shouldShowProductsTotal)
    }

    @ViewBuilder var customAmountsRow: some View {
        TitleAndValueRow(title: Localization.customAmountsTotal, value: .content(viewModel.customAmountsTotal))
            .renderedIf(viewModel.shouldShowTotalCustomAmounts)
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

    @ViewBuilder var giftCardsSection: some View {
        Group {
            if let giftCard {
                editGiftCardRow(giftCard: giftCard)
            }

            appliedGiftCardsSection
        }
        .renderedIf(viewModel.isGiftCardEnabled)
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
            .renderedIf(viewModel.taxBasedOnSetting != nil)
        }
        .padding(Constants.sectionPadding)
        .renderedIf(viewModel.taxLineViewModels.isNotEmpty)
        .fullScreenCover(isPresented: $shouldShowTaxEducationalDialog) {
            TaxEducationalDialogView(viewModel: viewModel.taxEducationalDialogViewModel,
                                     onDismissWpAdminWebView: viewModel.onDismissWpAdminWebViewClosure)
            .background(FullScreenCoverClearBackgroundView())
        }
    }

    @ViewBuilder var taxSectionTitle: some View {
        AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.taxesAdaptativeStacksSpacing) {
            Text(Localization.taxes)
                .bodyStyle()

            Button {
                shouldShowTaxEducationalDialog = true
                viewModel.onTaxHelpButtonTappedClosure()
            } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(Color(.wooCommercePurple(.shade60)))
                    .accessibilityLabel(Localization.taxInformationAccessibilityLabel)
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
                        .foregroundColor(Color(uiColor: .secondaryLabel))
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

    @ViewBuilder var discountsTotalRow: some View {
        TitleAndValueRow(title: Localization.discountTotal, value: .content(viewModel.discountTotal))
            .renderedIf(viewModel.shouldShowDiscountTotal)
    }

    @ViewBuilder var orderTotalRow: some View {
        TitleAndValueRow(title: Localization.orderTotal, value: .content(viewModel.orderTotal), bold: true, selectionStyle: .none) {}
            .padding(.bottom, Constants.orderTotalBottomPadding)
            .renderedIf(!viewModel.orderIsEmpty)

    }

    var rowsEditImage: Image? {
        viewModel.showNonEditableIndicators ? nil : Image(systemName: "pencil")
    }

    var editableRowsSelectionStyle: TitleAndValueRow.SelectionStyle {
        viewModel.showNonEditableIndicators ? .none : .highlight
    }
}

// MARK: Constants
private extension OrderPaymentSection {
    enum Localization {
        static let paymentTotals = NSLocalizedString("orderPaymentSection.paymentTotals",
                                                     value: "Payment totals",
                                                     comment: "Title text of the section that shows Payment details when creating a new order")
        static let productsTotal = NSLocalizedString("orderPaymentSection.products",
                                                     value: "Products",
                                                     comment: "Label for the row showing the total cost of products in the order")
        static let orderTotal = NSLocalizedString("Order total", comment: "Label for the the row showing the total cost of the order")
        static let discountTotal = NSLocalizedString("Discount total", comment: "Label for the the row showing the total discount of the order")
        static let shippingTotal = NSLocalizedString("Shipping", comment: "Label for the row showing the cost of shipping in the order")
        static let customAmountsTotal = NSLocalizedString("orderPaymentSection.customAmounts",
                                                          value: "Custom amounts",
                                                          comment: "Label for the row showing the cost of fees in the order")
        static let taxes = NSLocalizedString("Taxes", comment: "Label for the row showing the taxes in the order")
        static let coupon = NSLocalizedString("Coupon", comment: "Label for the row showing the cost of coupon in the order")
        static let taxRateAddedAutomaticallyRowText = NSLocalizedString("Tax rate location added automatically",
                                                                        comment: "Notice in editable order details when the tax rate was added to the order")
        static let taxInformationAccessibilityLabel = NSLocalizedString(
            "order.form.paymentSection.taxes.moreInfo.accessibilityLabel",
            value: "Tax information",
            comment: "An accessibility label for a More info button, rendered as a question mark icon, which shows tax information.")
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

struct OrderPaymentSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00", orderTotal: "20.00")

        OrderPaymentSection(viewModel: viewModel,
                            shouldShowShippingLineDetails: .constant(false),
                            shouldShowGiftCardForm: .constant(false))
            .previewLayout(.sizeThatFits)
    }
}
