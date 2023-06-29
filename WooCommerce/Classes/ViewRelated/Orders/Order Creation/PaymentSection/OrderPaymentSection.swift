import SwiftUI
import Yosemite

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

    /// Indicates if the coupon line details screen should be shown with an existing coupon.
    ///
    @State private var shouldShowExistingCouponLineDetails: Bool = false

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

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
                    FeeLineDetails(viewModel: viewModel.feeLineViewModel)
                }

            ForEach(viewModel.couponLineViewModels, id: \.title) { viewModel in
                CouponSummaryRow(couponSummary: viewModel.title,
                                 discount: viewModel.discount,
                                 shouldShowCouponLineDetails: $shouldShowExistingCouponLineDetails)
                    .sheet(isPresented: $shouldShowExistingCouponLineDetails) {
                        CouponLineDetails(viewModel: viewModel.detailsViewModel)
                    }
            }

            addCouponRow
                .sheet(isPresented: $shouldShowAddCouponLineDetails) {
                    CouponLineDetails(viewModel: viewModel.addCouponLineViewModel)
                }

            TitleAndValueRow(title: Localization.taxesTotal, value: .content(viewModel.taxesTotal))

            TitleAndValueRow(title: Localization.orderTotal, value: .content(viewModel.orderTotal), bold: true, selectionStyle: .none) {}
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground(modal: true)))

        Divider()
    }

    @ViewBuilder private var shippingRow: some View {
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

    @ViewBuilder private var feesRow: some View {
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

    @ViewBuilder private var addCouponRow: some View {
        Button(Localization.addCoupon) {
            shouldShowAddCouponLineDetails = true
        }
        .buttonStyle(PlusButtonStyle())
        .padding()
        .accessibilityIdentifier("add-coupon-button")
        .disabled(viewModel.shouldDisableAddingCoupons)
    }
}

struct CouponSummaryRow: View {
    let couponSummary: String
    let discount: String

    @Binding var shouldShowCouponLineDetails: Bool


    var body: some View {
        TitleAndValueRow(title: couponSummary, value: .content(discount), selectionStyle: .highlight) {
            shouldShowCouponLineDetails = true
        }
    }
}

// MARK: Constants
private extension OrderPaymentSection {
    enum Localization {
        static let payment = NSLocalizedString("Payment", comment: "Title text of the section that shows Payment details when creating a new order")
        static let productsTotal = NSLocalizedString("Products Total", comment: "Label for the row showing the total cost of products in the order")
        static let orderTotal = NSLocalizedString("Order Total", comment: "Label for the the row showing the total cost of the order")
        static let addShipping = NSLocalizedString("Add Shipping", comment: "Title text of the button that adds shipping line when creating a new order")
        static let shippingTotal = NSLocalizedString("Shipping", comment: "Label for the row showing the cost of shipping in the order")
        static let addFee = NSLocalizedString("Add Fee", comment: "Title text of the button that adds a fee when creating a new order")
        static let feesTotal = NSLocalizedString("Fees", comment: "Label for the row showing the cost of fees in the order")
        static let taxesTotal = NSLocalizedString("Taxes", comment: "Label for the row showing the taxes in the order")
        static let coupon = NSLocalizedString("Coupon", comment: "Label for the row showing the cost of coupon in the order")
        static let addCoupon = NSLocalizedString("Add Coupon", comment: "Title text of the button that adds a coupon when creating a new order")
    }
}

struct OrderPaymentSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00", orderTotal: "20.00")

        OrderPaymentSection(viewModel: viewModel)
            .previewLayout(.sizeThatFits)
    }
}
