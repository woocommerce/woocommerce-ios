import SwiftUI

/// View showing a list of products to add to an order.
///
struct AddProductToOrder: View {
    /// Defines whether the view is presented.
    ///
    @Binding var isPresented: Bool

    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: AddProductToOrderViewModel

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.syncStatus {
                case .success:
                    List(viewModel.productRows) { viewModel in
                        ProductRow(viewModel: viewModel)
                    }
                    .listStyle(PlainListStyle())
                case .error:
                    EmptyState(title: Localization.emptyStateMessage, image: .emptyProductsTabImage)
                        .frame(maxHeight: .infinity)
                case .firstPageLoad:
                    List(viewModel.ghostRows) { viewModel in
                        ProductRow(viewModel: viewModel)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                default:
                    EmptyView()
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        isPresented.toggle()
                    }
                }
            }
        }
        .wooNavigationBarStyle()
    }
}

private extension AddProductToOrder {
    enum Localization {
        static let title = NSLocalizedString("Add Product", comment: "Title for the screen to add a product to an order")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Add Product screen")
        static let emptyStateMessage = NSLocalizedString("No products found",
                                                         comment: "Message displayed if there are no products to display in the Add Product screen")
    }
}

struct AddProduct_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AddProductToOrderViewModel(siteID: 123)

        AddProductToOrder(isPresented: .constant(true), viewModel: viewModel)
    }
}
