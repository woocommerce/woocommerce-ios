import SwiftUI
import Yosemite

/// Represents the Payment section in an order
///
struct OrderPaymentSection: View {
    /// View model to drive the view content
    let viewModel: NewOrderViewModel.PaymentDataViewModel

    /// Indicates if the shipping line details screen should be shown or not.
    ///
    @State private var shouldShowShippingLineDetails: Bool = false

    /// Indicates if the fee line details screen should be shown or not.
    ///
    @State private var shouldShowFeeLineDetails: Bool = false

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        Divider()

        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text(Localization.payment)
                    .headlineStyle()

                Spacer()

                ProgressView()
                    .renderedIf(viewModel.isLoading)
            }
            .padding()

            TitleAndValueRow(title: Localization.productsTotal, value: .content(viewModel.itemsTotal), selectionStyle: .none) {}

            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.orderCreation) {
                shippingRow
                    .sheet(isPresented: $shouldShowShippingLineDetails) {
                        ShippingLineDetails(viewModel: viewModel.shippingLineViewModel)
                    }
                feesRow
                    .sheet(isPresented: $shouldShowFeeLineDetails) {
                        FeeLineDetails(viewModel: viewModel.feeLineViewModel)
                    }
            }

            TitleAndValueRow(title: Localization.orderTotal, value: .content(viewModel.orderTotal), bold: true, selectionStyle: .none) {}

            Text(Localization.taxesInfo)
                .footnoteStyle()
                .padding([.horizontal, .bottom])
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground))

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
        }
    }

    @ViewBuilder private var feesRow: some View {
        if viewModel.shouldShowFees {
            TitleAndValueRow(title: Localization.feesTotal, value: .content(viewModel.feesTotal), selectionStyle: .highlight) {
                shouldShowFeeLineDetails = true
            }
        } else {
            Button(Localization.addFees) {
                shouldShowFeeLineDetails = true
            }
            .buttonStyle(PlusButtonStyle())
            .padding()
        }
    }
}

// MARK: Constants
private extension OrderPaymentSection {
    enum Localization {
        static let payment = NSLocalizedString("Payment", comment: "Title text of the section that shows Payment details when creating a new order")
        static let productsTotal = NSLocalizedString("Products Total", comment: "Label for the row showing the total cost of products in the order")
        static let orderTotal = NSLocalizedString("Order Total", comment: "Label for the the row showing the total cost of the order")
        static let taxesInfo = NSLocalizedString("Taxes will be automatically calculated based on your store settings.",
                                                 comment: "Information about taxes and the order total when creating a new order")
        static let addShipping = NSLocalizedString("Add Shipping", comment: "Title text of the button that adds shipping line when creating a new order")
        static let shippingTotal = NSLocalizedString("Shipping", comment: "Label for the row showing the cost of shipping in the order")
        static let addFees = NSLocalizedString("Add Fees", comment: "Title text of the button that adds fees when creating a new order")
        static let feesTotal = NSLocalizedString("Fees", comment: "Label for the row showing the cost of fees in the order")
    }
}

struct OrderPaymentSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00", orderTotal: "20.00")

        OrderPaymentSection(viewModel: viewModel)
            .previewLayout(.sizeThatFits)
    }
}
