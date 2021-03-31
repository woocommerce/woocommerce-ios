import SwiftUI
import Yosemite

struct ShippingLabelPackageDetails: View {
    @State private var viewModel: ShippingLabelPackageDetailsViewModel

    init(viewModel: ShippingLabelPackageDetailsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ShippingLabelPackageNumberRow(packageNumber: 1, numberOfItems: viewModel.orderItems.count)

                ListHeaderView(text: Localization.itemsToFulfillHeader, alignment: .left)
                    .background(Color(.listBackground))

                ForEach(viewModel.itemsRows) { productItemRow in
                    Divider()
                    productItemRow
                }

                ListHeaderView(text: Localization.packageDetailsHeader, alignment: .left)
                    .background(Color(.listBackground))

                TitleAndValueRow(title: Localization.packageSelected, value: "To be implemented", selectable: true) {
                    // TODO: open package selection screen
                    print("Tapped")
                }

                Divider()

                TitleAndTextFieldRow(title: Localization.totalPackageWeight,
                                     placeholder: "0",
                                     text: .constant(""),
                                     symbol: "oz",
                                     keyboardType: .decimalPad)
                Divider()

                ListHeaderView(text: Localization.footer, alignment: .left)
                    .background(Color(.listBackground))
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.listBackground))
    }
}

private extension ShippingLabelPackageDetails {
    enum Localization {
        static let itemsToFulfillHeader = NSLocalizedString("ITEMS TO FULFILL", comment: "Header section items to fulfill in Shipping Label Package Detail")
        static let packageDetailsHeader = NSLocalizedString("PACKAGE DETAILS", comment: "Header section package details in Shipping Label Package Detail")
        static let packageSelected = NSLocalizedString("Package Selected",
                                                       comment: "Title of the row for selecting a package in Shipping Label Package Detail screen")
        static let totalPackageWeight = NSLocalizedString("Total package weight",
                                                          comment: "Title of the row for adding the package weight in Shipping Label Package Detail screen")
        static let footer = NSLocalizedString("Sum of products and package weight",
                                              comment: "Title of the footer in Shipping Label Package Detail screen")
    }
}

struct ShippingLabelPackageDetails_Previews: PreviewProvider {

    static var previews: some View {

        let viewModel = ShippingLabelPackageDetailsViewModel(items: ShippingLabelPackageDetails_Previews.sampleItems(),
                                                             currency: ShippingLabelPackageDetails_Previews.sampleCurrency())

        ShippingLabelPackageDetails(viewModel: viewModel)
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        ShippingLabelPackageDetails(viewModel: viewModel)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")
    }
}


// MARK: - Private Methods
//
private extension ShippingLabelPackageDetails_Previews {

    static func sampleItems() -> [OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product)",
                              productID: 52,
                              variationID: 0,
                              quantity: 2,
                              price: NSDecimalNumber(integerLiteral: 30),
                              sku: "",
                              subtotal: "50.00",
                              subtotalTax: "2.00",
                              taxClass: "",
                              taxes: [.init(taxID: 1, subtotal: "2", total: "1.2")],
                              total: "30.00",
                              totalTax: "1.20",
                              attributes: [])

        let item2 = OrderItem(itemID: 891,
                              name: "Fruits Bundle",
                              productID: 234,
                              variationID: 0,
                              quantity: 1.5,
                              price: NSDecimalNumber(integerLiteral: 0),
                              sku: "5555-A",
                              subtotal: "10.00",
                              subtotalTax: "0.40",
                              taxClass: "",
                              taxes: [.init(taxID: 1, subtotal: "0.4", total: "0")],
                              total: "0.00",
                              totalTax: "0.00",
                              attributes: [])

        return [item1, item2]
    }

    static func sampleCurrency() -> String {
        return "USD"
    }
}
