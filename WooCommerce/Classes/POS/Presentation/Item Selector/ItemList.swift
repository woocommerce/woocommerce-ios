import SwiftUI
import enum Yosemite.POSItem
import protocol WooFoundation.Analytics
import struct Yosemite.POSVariableParentProduct

/// Displays a list of POS items or placeholder card based on the given state.
struct ItemList: View {
    let state: ItemListState

    init(state: ItemListState) {
        self.state = state
    }

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
    let analytics: Analytics = ServiceLocator.analytics
    @EnvironmentObject var posModel: PointOfSaleAggregateModel

    var body: some View {
        switch item {
        case let .simpleProduct(product):
            Button(action: {
                posModel.addToCart(product)
                analytics.track(event: .PointOfSale.addItemToCart(type: .simpleProduct))
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
                posModel.addToCart(variation)
                analytics.track(event: .PointOfSale.addItemToCart(type: .variation))
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
                    ]
                )
    )
}

#Preview("Loading") {
    ItemList(state: .loading([]))
}

#endif
