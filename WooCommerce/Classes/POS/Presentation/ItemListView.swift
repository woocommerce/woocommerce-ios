import SwiftUI
import protocol Yosemite.POSItem

struct ItemListView: View {
    @ObservedObject var viewModel: ItemSelectorViewModel

    init(viewModel: ItemSelectorViewModel) {
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
            case .loaded:
                ScrollView {
                    ForEach(viewModel.items, id: \.productID) { item in
                        Button(action: {
                            viewModel.select(item)
                        }, label: {
                            ItemCardView(item: item)
                        })
                    }
                }
            case .loading:
                loadingView
            case .error:
                errorView
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

    var errorView: some View {
        VStack {
            Spacer()
            Text("Error!!")
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
    ItemListView(viewModel: ItemSelectorViewModel(itemProvider: POSItemProviderPreview()))
}
#endif
