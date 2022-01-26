import SwiftUI
import Yosemite

/// View to show a single product in an order, with the option to remove it from the order.
///
struct ProductInOrder: View {

    @Environment(\.presentationMode) private var presentation

    /// View model to drive the view content
    ///
    let viewModel: ProductInOrderViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Layout.noSpacing) {
                    Section {
                        Divider()
                        ProductRow(viewModel: viewModel.productRowViewModel)
                            .padding()
                        Divider()
                    }
                    .background(Color(.listForeground))

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
                    .background(Color(.listForeground))
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
        static let remove = NSLocalizedString("Remove product from order",
                                              comment: "Text for the button to remove a product from the order during order creation")
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
                                            imageURL: nil)
        let viewModel = ProductInOrderViewModel(productRowViewModel: productRowVM,
                                                onRemoveProduct: {})
        ProductInOrder(viewModel: viewModel)
    }
}
