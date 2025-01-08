import SwiftUI
import enum Yosemite.POSItem
import struct Yosemite.POSVariableParentProduct

/// Displays a list of POS items or placeholder card based on the given state.
struct ItemList<HeaderView: View>: View {
    enum BaseItem {
        case root
        case parent(POSItem)
    }

    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize
    @EnvironmentObject var posModel: PointOfSaleAggregateModel
    let state: ItemListState
    private let node: BaseItem
    private let headerView: HeaderView

    init(state: ItemListState,
         node: BaseItem = .root,
         @ViewBuilder headerView: () -> HeaderView = { EmptyView() }) {
        self.state = state
        self.node = node
        self.headerView = headerView()
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                headerView

                ForEach(state.items) { item in
                    ItemListRow(item: item)
                }

                switch state {
                case .loading, .loaded(_, hasMoreItems: true):
                    GhostItemCardView()
                        .onAppear {
                            guard case .root = node else { return }
                            Task { await posModel.loadNextItems() }
                        }
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, floatingControlAreaSize.height)
            .padding(.horizontal, Constants.itemListPadding)
        }
    }
}

private enum Constants {
    static let itemListPadding: CGFloat = 16
}

private struct ItemListRow: View {
    let item: POSItem
    @EnvironmentObject var posModel: PointOfSaleAggregateModel

    var body: some View {
        switch item {
        case let .simpleProduct(product):
            Button(action: {
                posModel.addToCart(product)
            }, label: {
                SimpleProductCardView(product: product)
            })
        case let .variableParentProduct(parentProduct):
            NavigationLink(value: item) {
                ParentProductCardView(name: parentProduct.name,
                                      imageSource: parentProduct.productImageSource,
                                      detailView: {
                    Text(Localization.variationsAvailable)
                        .foregroundStyle(Color.posSecondaryText)
                        .font(.posBodyRegular)
                })
            }
        case let .variation(variation):
            Button(action: {
                print("Tapped variation \(variation.name)")
            }, label: {
                VariationCardView(variation: variation)
            })
        }
    }
}

private extension ItemListRow {
    enum Localization {
        static let variationsAvailable = NSLocalizedString(
            "pos.parentProductCard.optionsAvailable",
            value: "Options available",
            comment: "Text indicating that there are options available for a parent product"
        )
    }
}

#if DEBUG

#Preview("Loaded with items") {
    ItemList(
        state:
                .loaded(
                    [
                        .simpleProduct(
                            .init(
                                id: .init(),
                                name: "Strong latte 16oz",
                                formattedPrice: "$4.00",
                                productID: 12,
                                price: "4.00"
                            )
                        ),
                        .variableParentProduct(
                            .init(
                                id: .init(),
                                name: "Variable mocha",
                                productImageSource: "https://pd.w.org/2024/12/986762d0d4d4cf17.82435881-scaled.jpeg",
                                productID: 16
                            )
                        )
                    ],
                    hasMoreItems: false
                )
    )
}

#Preview("Loading") {
    ItemList(state: .loading([]))
}

#endif
