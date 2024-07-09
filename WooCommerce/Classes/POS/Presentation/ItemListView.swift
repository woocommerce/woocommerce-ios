import SwiftUI
import protocol Yosemite.POSItem

struct ItemListView: View {
    @ObservedObject var viewModel: ItemSelectorViewModel

    init(viewModel: ItemSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Products")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .font(Constants.titleFont)
                .foregroundColor(Color.posPrimaryTexti3)
            if viewModel.isSyncingItems {
                Spacer()
                Text("Loading...")
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

private extension ItemListView {
    enum Constants {
        static let titleFont: Font = .system(size: 40, weight: .bold, design: .default)
    }
}

#if DEBUG
#Preview {
    ItemListView(viewModel: ItemSelectorViewModel(itemProvider: POSItemProviderPreview()))
}
#endif
