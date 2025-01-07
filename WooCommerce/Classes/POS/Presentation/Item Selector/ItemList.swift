import SwiftUI
import enum Yosemite.POSItem

/// Displays a list of POS items or placeholder card based on the given state.
struct ItemList: View {
    let state: ItemListState

    var body: some View {
        ForEach(state.items) { item in
            ItemListRow(item: item)
        }
        GhostItemCardView()
            .renderedIf(state.isLoading)
    }
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
        case let .parentProduct(parentProduct):
            NavigationLink(value: item) {
                ParentProductCardView(parentProduct: parentProduct)
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
                        .parentProduct(
                            .init(
                                id: .init(),
                                name: "Variable mocha",
                                productImageSource: "https://pd.w.org/2024/12/986762d0d4d4cf17.82435881-scaled.jpeg",
                                productID: 16,
                                type: .variable
                            )
                        )
                    ]
                )
    )
}

#Preview("Loading") {
    ItemList(state: .loading([]))
}

#endif
