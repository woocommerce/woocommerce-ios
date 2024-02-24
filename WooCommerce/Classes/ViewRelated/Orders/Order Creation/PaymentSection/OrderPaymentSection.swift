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
        VStack(alignment: .leading, spacing: .zero) {
            // Order components
            Group {
                productsRow

                customAmountsRow

                existingShippingRow

                appliedCouponsRows

                giftCardsSection

                taxesSection
            }

            // Subtotals
            discountsTotalRow
        }
        .background(Color(.listForeground(modal: false)))

        taxRateAddedAutomaticallyRow
            .renderedIf(viewModel.shouldShowStoredTaxRateAddedAutomatically)
    }
}

private extension OrderPaymentSection {
    @ViewBuilder var appliedCouponsRows: some View {
        VStack {
            ForEach(viewModel.couponLineViewModels, id: \.title) { viewModel in
                VStack(alignment: .leading, spacing: .zero) {
                    TitleAndValueRow(title: Localization.coupon,
                                     titleSuffixImage: (image: rowsEditImage, color: Color(.primary)),
                                     value: .content(viewModel.discount),
                                     selectionStyle: editableRowsSelectionStyle) {
                        selectedCouponLineDetailsViewModel = viewModel.detailsViewModel
                    }
                    Text(viewModel.detailsViewModel.code)
                        .footnoteStyle()
                        .padding(.horizontal, Constants.horizontalPadding)
                }
            }
        }
        .sheet(item: $selectedCouponLineDetailsViewModel) { viewModel in
            CouponLineDetails(viewModel: viewModel)
        }
    }

    @ViewBuilder var existingShippingRow: some View {
        TitleAndValueRow(title: Localization.shippingTotal,
                         titleSuffixImage: (image: rowsEditImage, color: Color(.primary)),
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
            shippingTax
                .renderedIf(viewModel.shouldShowShippingTax)
            taxBasedOnLine
                .onTapGesture {
                    shouldShowTaxEducationalDialog = true
                    viewModel.onTaxHelpButtonTappedClosure()
                }
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

    @ViewBuilder var shippingTax: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.taxesAdaptativeStacksSpacing) {
                Text(Localization.shippingTax)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(viewModel.shippingTax)
                    .footnoteStyle()
                    .multilineTextAlignment(.trailing)
                    .frame(width: nil, alignment: .trailing)
            }
        }
    }

    @ViewBuilder var taxBasedOnLine: some View {
        HStack(spacing: Constants.taxBasedOnLineTextPadding) {
            Text(viewModel.taxBasedOnSetting?.displayString ?? "")
                .footnoteStyle()
                .multilineTextAlignment(.leading)
            Text(Localization.taxInformationLearnMore)
                .font(.footnote)
                .foregroundColor(Color(.wooCommercePurple(.shade60)))
                .renderedIf(viewModel.shouldShowTaxesInfoButton)
        }

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
        }
        .background(Color(.listForeground(modal: false)))
    }

    @ViewBuilder var discountsTotalRow: some View {
        TitleAndValueRow(title: Localization.discountTotal, value: .content(viewModel.discountTotal))
            .renderedIf(viewModel.shouldShowDiscountTotal)
    }

    var rowsEditImage: Image {
        viewModel.showNonEditableIndicators ? Image(uiImage: .lockImage) : Image(systemName: "pencil")
    }

    var editableRowsSelectionStyle: TitleAndValueRow.SelectionStyle {
        viewModel.showNonEditableIndicators ? .none : .highlight
    }
}

// MARK: Constants
private extension OrderPaymentSection {
    enum Localization {
        static let productsTotal = NSLocalizedString(
            "orderPaymentSection.productsTotal",
            value: "Products",
            comment: "Label for the row showing the total cost of products in the order")
        static let discountTotal = NSLocalizedString(
            "orderPaymentSection.discountTotal",
            value: "Discount total",
            comment: "Label for the the row showing the total discount of the order")
        static let shippingTotal = NSLocalizedString(
            "orderPaymentSection.shippingTotal",
            value: "Shipping",
            comment: "Label for the row showing the cost of shipping in the order")
        static let customAmountsTotal = NSLocalizedString(
            "orderPaymentSection.customAmountsTotal",
            value: "Custom amounts",
            comment: "Label for the row showing the cost of fees in the order")
        static let taxes = NSLocalizedString(
            "orderPaymentSection.taxes",
            value: "Taxes",
            comment: "Label for the row showing the taxes in the order")
        static let coupon = NSLocalizedString(
            "orderPaymentSection.coupon",
            value: "Coupon",
            comment: "Label for the row showing the cost of coupon in the order")
        static let taxRateAddedAutomaticallyRowText = NSLocalizedString(
            "orderPaymentSection.taxRateAddedAutomaticallyRowText",
            value: "Tax rate location added automatically",
            comment: "Notice in editable order details when the tax rate was added to the order")
        static let taxInformationLearnMore = NSLocalizedString(
            "order.form.paymentSection.taxes.learnMore",
            value: "Learn More.",
            comment: "A 'Learn More' label text, which shows tax information upon being clicked.")
        static let shippingTax = NSLocalizedString(
            "order.form.paymentSection.taxes.shippingTax",
            value: "Shipping Tax",
            comment: "Label for the row showing the shipping tax.")
    }

    enum Constants {
        static let giftCardsSectionVerticalSpacing: CGFloat = 8
        static let taxesSectionVerticalSpacing: CGFloat = 8
        static let taxRateAddedAutomaticallyRowHorizontalSpacing: CGFloat = 8
        static let taxesAdaptativeStacksSpacing: CGFloat = 4
        static let taxBasedOnLineTextPadding: CGFloat = 4
        static let sectionPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let rowMinHeight: CGFloat = 44
        static let infoTooltipCornerRadius: CGFloat = 4
    }
}

struct OrderPaymentSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00")

        OrderPaymentSection(viewModel: viewModel,
                            shouldShowShippingLineDetails: .constant(false),
                            shouldShowGiftCardForm: .constant(false))
            .previewLayout(.sizeThatFits)
    }
}
