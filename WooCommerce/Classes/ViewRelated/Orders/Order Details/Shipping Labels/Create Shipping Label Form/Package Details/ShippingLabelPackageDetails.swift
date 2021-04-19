import SwiftUI
import Yosemite

struct ShippingLabelPackageDetails: View {
    @ObservedObject private var viewModel: ShippingLabelPackageDetailsViewModel
    @State private var showingAddPackage = false

    init(viewModel: ShippingLabelPackageDetailsViewModel) {
        _viewModel = ObservedObject(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ShippingLabelPackageNumberRow(packageNumber: 1, numberOfItems: viewModel.itemsRows.count)

                ListHeaderView(text: Localization.itemsToFulfillHeader, alignment: .left)
                    .background(Color(.listBackground))

                ForEach(viewModel.itemsRows) { productItemRow in
                    Divider()
                    productItemRow
                }

                ListHeaderView(text: Localization.packageDetailsHeader, alignment: .left)
                    .background(Color(.listBackground))

                TitleAndValueRow(title: Localization.packageSelected, value: "To be implemented", selectable: true) {
                    showingAddPackage.toggle()
                }

                NavigationLink(
                    destination: ShippingLabelPackageSelected(siteID: viewModel.siteID),
                    isActive: $showingAddPackage) { EmptyView()
                }
                Divider()

                TitleAndTextFieldRow(title: Localization.totalPackageWeight,
                                     placeholder: "0",
                                     text: .constant(""),
                                     symbol: viewModel.weightUnit,
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

        let viewModel = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetails_Previews.sampleOrder())

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

    static func sampleOrder() -> Order {
        return Order(siteID: 1234,
                     orderID: 963,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     status: .processing,
                     currency: "USD",
                     customerNote: "",
                     dateCreated: date(with: "2018-04-03T23:05:12"),
                     dateModified: date(with: "2018-04-03T23:05:14"),
                     datePaid: date(with: "2018-04-03T23:05:14"),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodID: "stripe",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: sampleItems(),
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     shippingLines: sampleShippingLines(),
                     coupons: sampleCoupons(),
                     refunds: [],
                     fees: [])
    }

    static func sampleAddress() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    static func sampleShippingLines() -> [ShippingLine] {
        return [ShippingLine(shippingID: 123,
                             methodTitle: "International Priority Mail Express Flat Rate",
                             methodID: "usps",
                             total: "133.00",
                             totalTax: "0.00",
                             taxes: [.init(taxID: 1, subtotal: "", total: "0.62125")])]
    }

    static func sampleCoupons() -> [OrderCouponLine] {
        let coupon1 = OrderCouponLine(couponID: 894,
                                      code: "30$off",
                                      discount: "30",
                                      discountTax: "1.2")

        return [coupon1]
    }

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

    static func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }

    static func taxes() -> [OrderItemTax] {
        return [OrderItemTax(taxID: 75, subtotal: "0.45", total: "0.45")]
    }
}
