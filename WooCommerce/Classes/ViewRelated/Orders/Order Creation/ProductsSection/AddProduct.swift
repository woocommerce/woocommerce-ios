import SwiftUI

/// View showing a list of products to add to an order.
///
struct AddProduct: View {
    /// Defines whether the view is presented.
    ///
    @Binding var isPresented: Bool

    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: AddProductViewModel

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    switch viewModel.syncStatus {
                    case .success:
                        // TODO: Make the product list searchable
                        LazyVStack {
                            ForEach(viewModel.productRows) { viewModel in
                                ProductRow(viewModel: viewModel)
                            }

                            // Infinite scroll indicator
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                                .renderedIf(viewModel.hasMoreProducts)
                                .onAppear {
                                    viewModel.loadMoreProducts()
                                }
                        }
                        .padding()
                    case .error:
                        EmptyState(title: Localization.emptyStateMessage, image: .emptyProductsTabImage)
                            .frame(height: geometry.size.height)
                            .background(Color(.listBackground))
                    case .firstPageLoad:
                        ForEach(viewModel.ghostRows) { viewModel in
                            ProductRow(viewModel: viewModel)
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                        .padding()
                    default:
                        EmptyView()
                    }
                }
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
        }
        .wooNavigationBarStyle()
    }
}

private extension AddProduct {
    enum Localization {
        static let title = NSLocalizedString("Add Product", comment: "Title for the screen to add a product to an order")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Add Product screen")
        static let emptyStateMessage = NSLocalizedString("No products found",
                                                         comment: "Message displayed if there are no products to display in the Add Product screen")
    }
}

struct AddProduct_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AddProductViewModel(siteID: 123)

        AddProduct(isPresented: .constant(true), viewModel: viewModel)
    }
}
