import SwiftUI
import Yosemite

/// View to show a single product in an order, with the option to remove it from the order.
///
struct ProductInOrder: View {

    @Environment(\.presentationMode) private var presentation

    /// View model to drive the view content
    ///
    let viewModel: ProductInOrderViewModel

    /// Indicates if the discount line details screen should be shown or not.
    ///
    @State private var shouldShowDiscountLineDetails: Bool = false

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Layout.noSpacing) {
                    Section {
                        Divider()
                        ProductRow(viewModel: viewModel.productRowViewModel)
                            .padding()
                        Divider()
                        VStack(spacing: Layout.noSpacing) {
                            Button(Localization.addDiscount) {
                                viewModel.onAddDiscountTapped()
                                shouldShowDiscountLineDetails = true
                            }
                                .buttonStyle(PlusButtonStyle())
                                .padding()
                                .accessibilityIdentifier("add-discount-button")
                            Divider()
                        }
                        .renderedIf(viewModel.showAddDiscountRow)

                        Text(Localization.couponsAndDiscountAlert)
                            .subheadlineStyle()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .renderedIf(viewModel.showCouponsAndDiscountsAlert)
                    }
                    .background(Color(.listForeground(modal: false)))
                    .sheet(isPresented: $shouldShowDiscountLineDetails) {
                        FeeOrDiscountLineDetailsView(viewModel: viewModel.discountDetailsViewModel)
                    }
                    Spacer(minLength: Layout.sectionSpacing)

                    Section {
                        Divider()
                        VStack(alignment: .leading, spacing: Layout.noSpacing) {
                            HStack() {
                                Text(Localization.discountTitle)
                                    .headlineStyle()
                                Spacer()
                                Button(Localization.editDiscount) {
                                    viewModel.onEditDiscountTapped()
                                    shouldShowDiscountLineDetails = true
                                }
                            }

                            Spacer()
                            Text(Localization.discountAmount)
                                .subheadlineStyle()
                            Text(viewModel.formattedDiscount ?? "")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        Divider()
                    }
                    .background(Color(.listForeground(modal: false)))
                    .renderedIf(viewModel.showCurrentDiscountSection && viewModel.formattedDiscount != nil)

                    Spacer(minLength: Layout.sectionSpacing)

                    Section {
                        Divider()
                        Button(Localization.remove) {
                            viewModel.onRemoveProduct()
                            presentation.wrappedValue.dismiss()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(Color(.error))
                        Divider()
                    }
                    .background(Color(.listForeground(modal: false)))
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        }
        .wooNavigationBarStyle()
        .navigationViewStyle(.stack)
        .onReceive(viewModel.viewDismissPublisher) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: Constants
private extension ProductInOrder {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
        static let noSpacing: CGFloat = 0.0
    }

    enum Localization {
        static let title = NSLocalizedString("Product", comment: "Title for the Product screen during order creation")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Product screen")
        static let addDiscount = NSLocalizedString("Add discount",
                                              comment: "Text for the button to add a discount to a product during order creation")
        static let couponsAndDiscountAlert = NSLocalizedString("Adding discount is currently not available. Remove coupons first.",
                                              comment: "Alert on the Product Details screen during order creation when" +
                                                               "we cannot add a discount because we have coupons")
        static let remove = NSLocalizedString("Remove Product from Order",
                                              comment: "Text for the button to remove a product from the order during order creation")
        static let discountTitle = NSLocalizedString("Discount", comment: "Title for the Discount section on the Product Details screen during order creation")
        static let editDiscount = NSLocalizedString("Edit", comment: "Text for the button to edit a discount to a product during order creation")
        static let discountAmount = NSLocalizedString("Amount", comment: "Title for the discount amount of a product during order creation")
    }
}

struct ProductInOrder_Previews: PreviewProvider {
    static var previews: some View {
        let productRowVM = ProductRowViewModel(productOrVariationID: 1,
                                            name: "Love Ficus",
                                            sku: "123456",
                                            price: "20",
                                            stockStatusKey: "instock",
                                            stockQuantity: 7,
                                            manageStock: true,
                                            canChangeQuantity: false,
                                               imageURL: nil,
                                               hasParentProduct: true,
                                               isConfigurable: true)
        let viewModel = ProductInOrderViewModel(productRowViewModel: productRowVM,
                                                productDiscountConfiguration: nil, showCouponsAndDiscountsAlert: false,
                                                onRemoveProduct: {})
        ProductInOrder(viewModel: viewModel)
    }
}
