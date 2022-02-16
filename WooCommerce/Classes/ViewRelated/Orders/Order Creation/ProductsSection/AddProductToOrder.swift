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

    /// Keeps track of the current screen scale
    ///
    @ScaledMetric private var scale = 1

    var body: some View {
        NavigationView {
            VStack {
                SearchHeader(filterText: $viewModel.searchTerm, filterPlaceholder: Localization.searchPlaceholder)
                switch viewModel.syncStatus {
                case .results:
                    InfiniteScrollList(isLoading: viewModel.shouldShowScrollIndicator,
                                       loadAction: viewModel.syncNextPage) {
                        ForEach(viewModel.productRows) { rowViewModel in
                            createProductRow(rowViewModel: rowViewModel)
                                .padding(Constants.defaultPadding)
                            Divider().frame(height: Constants.dividerHeight)
                                .padding(.leading, Constants.defaultPadding)
                        }
                    }
                                       .background(Color(.listForeground))
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
                viewModel.onLoadTrigger.send()
            }
        }
        .wooNavigationBarStyle()
    }

    /// Creates the `ProductRow` for a product, depending on whether the product is variable.
    ///
    @ViewBuilder private func createProductRow(rowViewModel: ProductRowViewModel) -> some View {
        if rowViewModel.numberOfVariations > 0,
           let addVariationToOrderVM = viewModel.getVariationsViewModel(for: rowViewModel.productOrVariationID) {
            LazyNavigationLink(destination: AddProductVariationToOrder(isPresented: $isPresented, viewModel: addVariationToOrderVM)) {
                HStack {
                    ProductRow(viewModel: rowViewModel)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(uiImage: .chevronImage)
                        .resizable()
                        .flipsForRightToLeftLayoutDirection(true)
                        .frame(width: Constants.chevronSize(scale: scale), height: Constants.chevronSize(scale: scale))
                        .foregroundColor(Color(.systemGray))
                        .accessibility(hidden: true)
                }
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
    enum Constants {
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: CGFloat = 16
        static func chevronSize(scale: CGFloat) -> CGFloat {
            22 * scale
        }
    }

    enum Localization {
        static let title = NSLocalizedString("Add Product", comment: "Title for the screen to add a product to an order")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Add Product screen")
        static let emptyStateMessage = NSLocalizedString("No products found",
                                                         comment: "Message displayed if there are no products to display in the Add Product screen")
        static let searchPlaceholder = NSLocalizedString("Search Products", comment: "Placeholder on the search field to search for a specific product")
    }
}

struct AddProduct_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AddProductToOrderViewModel(siteID: 123)

        AddProductToOrder(isPresented: .constant(true), viewModel: viewModel)
    }
}
