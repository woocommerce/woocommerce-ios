import SwiftUI
import protocol Yosemite.POSItem

struct ItemListView: View {
    @ObservedObject var viewModel: ItemListViewModel

    init(viewModel: ItemListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            headerView()
            switch viewModel.state {
            case .empty(let emptyModel):
                emptyView(emptyModel)
            case .loading:
                loadingView
            case .loaded(let items):
                listView(items)
            case .error(let errorModel):
                errorView(errorModel)
            }
        }
        .refreshable {
            await viewModel.reload()
        }
        .padding(.horizontal, 32)
        .background(Color.posBackgroundGreyi3)
    }
}

/// View Helpers
///
private extension ItemListView {
    @ViewBuilder
    func headerView() -> some View {
        switch viewModel.isBannerVisible {
        case true:
            VStack {
                Text(Localization.productSelectorTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .font(Constants.titleFont)
                    .foregroundColor(Color.posPrimaryTexti3)
                // TODO:
                // Separate the banner card to its own view
                HStack {
                    Image(uiImage: .infoImage)
                    VStack {
                        Text("Showing simple products only")
                        Text("Only simple physical products are available with POS right now.")
                        Text("Other product types, such as variable and virtual, will become available in future updates.")
                    }
                    Button(action: {
                        viewModel.toggleBanner()
                    }, label: {
                        Image(uiImage: .closeButton)
                    })
                }
            }
        case false:
            HStack {
                Text(Localization.productSelectorTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .font(Constants.titleFont)
                    .foregroundColor(Color.posPrimaryTexti3)
                Spacer()
                Button(action: {
                    viewModel.toggleBanner()
                }, label: {
                    Image(uiImage: .infoImage)
                })
            }
        }
    }
    var loadingView: some View {
        VStack {
            Spacer()
            Text("Loading...")
            Spacer()
        }
    }

    @ViewBuilder
    func emptyView(_ content: ItemListViewModel.EmptyModel) -> some View {
        VStack {
            Spacer()
            Text(content.title)
            Text(content.subtitle)
            Button(action: {
                // TODO:
                // Redirect the merchant to the app in order to create a new product
                // https://github.com/woocommerce/woocommerce-ios/issues/13297
            }, label: {
                Text(content.buttonText)}
            )
            Text(content.hint)
            Spacer()
        }
    }

    @ViewBuilder
    func listView(_ items: [POSItem]) -> some View {
        ScrollView {
            ForEach(items, id: \.productID) { item in
                Button(action: {
                    viewModel.select(item)
                }, label: {
                    ItemCardView(item: item)
                })
            }
        }
    }

    @ViewBuilder
    func errorView(_ content: ItemListViewModel.ErrorModel) -> some View {
        VStack {
            Spacer()
            Text(content.title)
            Button(action: {
                Task {
                    await viewModel.populatePointOfSaleItems()
                }
            }, label: {
                Text(content.buttonText)
            })
            Spacer()
        }
    }
}

/// Constants
///
private extension ItemListView {
    enum Constants {
        static let titleFont: Font = .system(size: 40, weight: .bold, design: .default)
    }

    enum Localization {
        static let productSelectorTitle = NSLocalizedString(
            "pos.itemlistview.productSelectorTitle",
            value: "Products",
            comment: "Title of the Point of Sale product selector"
        )
    }
}

#if DEBUG
#Preview {
    ItemListView(viewModel: ItemListViewModel(itemProvider: POSItemProviderPreview()))
}
#endif
