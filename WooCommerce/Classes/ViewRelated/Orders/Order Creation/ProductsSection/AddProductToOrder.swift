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
                case .results:
                    InfiniteScrollList(isLoading: viewModel.shouldShowScrollIndicator,
                                       loadAction: viewModel.syncNextPage) {
                        ForEach(viewModel.productRows) { rowViewModel in
                            createProductRow(rowViewModel: rowViewModel)
                        }
                    }
                case .empty:
                    EmptyState(title: Localization.emptyStateMessage, image: .emptyProductsTabImage)
                        .frame(maxHeight: .infinity)
                case .firstPageSync:
                    List(viewModel.ghostRows) { rowViewModel in
                        ProductRow(viewModel: rowViewModel)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                    .listStyle(PlainListStyle())
                default:
                    EmptyView()
                }
            }
            .background(Color(.listBackground).ignoresSafeArea())
            .ignoresSafeArea(.container, edges: .horizontal)
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        isPresented.toggle()
                    }
                }
            }
            .onAppear {
                viewModel.syncFirstPage()
            }
        }
        .wooNavigationBarStyle()
    }

    @ViewBuilder private func createProductRow(rowViewModel: ProductRowViewModel) -> some View {
        if rowViewModel.numberOfVariations > 0 {
            NavigationLink {
                if let addVariationToOrderVM = viewModel.getVariationsViewModel(for: rowViewModel.productOrVariationID) {
                    AddProductVariationToOrder(isPresented: $isPresented, viewModel: addVariationToOrderVM)
                }
            } label: {
                ProductRow(viewModel: rowViewModel)
            }
        } else {
            ProductRow(viewModel: rowViewModel)
                .onTapGesture {
                    viewModel.selectProduct(rowViewModel.productOrVariationID)
                    isPresented.toggle()
                }
        }
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
