import SwiftUI
import Yosemite

/// Represents the Payment section in an order
///
struct OrderPaymentSection: View {
    /// View model to drive the view content
    let viewModel: NewOrderViewModel.PaymentDataViewModel

    /// Closure to create/update the shipping line object
    let saveShippingLineClosure: (ShippingLine?) -> Void

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        Divider()

        VStack(alignment: .leading, spacing: .zero) {
            Text(Localization.payment)
                .headlineStyle()
                .padding()

            TitleAndValueRow(title: Localization.productsTotal, value: .content(viewModel.itemsTotal), selectionStyle: .none) {}

            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.orderCreation) {
                shippingRow
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
                saveShippingLineClosure(nil)
            }
        } else {
            Button(Localization.addShipping) {
                let testShippingLine = ShippingLine(shippingID: 0,
                                                    methodTitle: "Flat Rate",
                                                    methodID: "other",
                                                    total: "10",
                                                    totalTax: "",
                                                    taxes: [])
                saveShippingLineClosure(testShippingLine)
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
        static let addShipping = NSLocalizedString("Add shipping", comment: "Title text of the button that adds shipping line when creating a new order")
        static let shippingTotal = NSLocalizedString("Shipping", comment: "Label for the row showing the cost of shipping in the order")
    }
}

struct OrderPaymentSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00", orderTotal: "20.00")

        OrderPaymentSection(viewModel: viewModel, saveShippingLineClosure: { _ in })
            .previewLayout(.sizeThatFits)
    }
}
