import SwiftUI
import protocol Yosemite.POSItem

struct ItemListView: View {
    @ObservedObject var viewModel: ItemListViewModel

    init(viewModel: ItemListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(Localization.productSelectorTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .font(Constants.titleFont)
                .foregroundColor(Color.posPrimaryTexti3)
            switch viewModel.state {
            case .empty(let emptyVM):
                emptyView(emptyVM)
            case .loading:
                loadingView
            case .loaded(let items):
                listView(items)
            case .error(let errorVM):
                errorView(errorVM)
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
    var loadingView: some View {
        VStack {
            Spacer()
            Text("Loading...")
            Spacer()
        }
    }

    @ViewBuilder
    func emptyView(_ emptyVM: ItemListEmpty) -> some View {
        VStack {
            Spacer()
            Text(emptyVM.title)
            Text(emptyVM.subtitle)
            Button(action: {
                // TODO:
                // Redirect the merchant to the app in order to create a new product
                // https://github.com/woocommerce/woocommerce-ios/issues/13297
            }, label: {
                Text(emptyVM.buttonText)} 
            )
            Text(emptyVM.hint)
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
    func errorView(_ errorVM: ItemListError) -> some View {
        VStack {
            Spacer()
            Text(errorVM.title)
            Button(action: {
                Task {
                    await viewModel.populatePointOfSaleItems()
                }
            }, label: { Text("Retry") })
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
