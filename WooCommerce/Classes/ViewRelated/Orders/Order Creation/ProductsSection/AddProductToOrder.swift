import SwiftUI

/// View showing a list of products or product variations to add to an order.
///
struct AddProductToOrder<ViewModel: AddProductToOrderViewModelProtocol>: View {
    /// Defines whether the view is presented.
    ///
    @Binding var isPresented: Bool

    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.syncStatus {
                case .results:
                    List {
                        ForEach(viewModel.productRows) { rowViewModel in
                            ProductRow(viewModel: rowViewModel)
                                .onTapGesture {
                                    viewModel.selectProduct(rowViewModel.productOrVariationID)
                                    isPresented.toggle()
                                }
                        }

                        InfiniteScrollIndicator(showContent: viewModel.shouldShowScrollIndicator)
                            .onAppear {
                                viewModel.syncNextPage()
                            }
                    }
                    .listStyle(PlainListStyle())
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
}

private struct InfiniteScrollIndicator: View {

    let showContent: Bool

    var body: some View {
        if #available(iOS 15.0, *) {
            createProgressView()
                .listRowSeparator(.hidden, edges: .bottom)
        } else {
            createProgressView()
        }
    }

    @ViewBuilder func createProgressView() -> some View {
        ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.listBackground))
            .if(!showContent) { progressView in
                progressView.hidden() // Hidden but still in view hierarchy so `onAppear` will trigger sync when needed
            }
    }
}

private enum Localization {
    static let title = NSLocalizedString("Add Product", comment: "Title for the screen to add a product to an order")
    static let close = NSLocalizedString("Close", comment: "Text for the close button in the Add Product screen")
    static let emptyStateMessage = NSLocalizedString("No products found",
                                                     comment: "Message displayed if there are no products to display in the Add Product screen")
}

struct AddProduct_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AddProductToOrderViewModel(siteID: 123)

        AddProductToOrder(isPresented: .constant(true), viewModel: viewModel)
    }
}
