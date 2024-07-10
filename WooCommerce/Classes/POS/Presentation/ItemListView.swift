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
            if viewModel.state == .loading {
                Spacer()
                Text("Loading...")
                Spacer()
            } else if viewModel.state == .error {
                Spacer()
                Text("Error!!")
                Spacer()
            } else {
                ScrollView {
                    ForEach(viewModel.items, id: \.productID) { item in
                        Button(action: {
                            viewModel.select(item)
                        }, label: {
                            ItemCardView(item: item)
                        })
                    }
                }
            }
        }
        .refreshable {
            await viewModel.reload()
        }
        .padding(.horizontal, 32)
        .background(Color.posBackgroundGreyi3)
    }
}

/// View helpers
///
private extension ItemListView {
    
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
