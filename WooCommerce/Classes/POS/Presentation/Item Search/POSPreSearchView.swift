import SwiftUI
import enum Yosemite.POSItem

@available(iOS 17.0, *)
struct POSPreSearchView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel

    let savedSearches: [String]
    let onSearchSelected: (String) -> Void

    let itemListType: ItemListType

    var body: some View {
        // List of popular items
        ItemList(
            itemsController: posModel.popularPurchasableItemsController,
            node: .root,
            itemActionHandler: StandardPOSItemActionHandler(posModel: posModel, itemListType: itemListType),
            headerView: {
                if savedSearches.isEmpty {
                    Text(Localization.preSearchEmptyListText)
                        .font(.posBodyLargeRegular())
                        .foregroundColor(.posOnSurface)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, POSPadding.medium)
                }
                
                // Column header
                Text(Localization.popularProductsTitle)
                    .font(POSFontStyle.posBodyMediumBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity, alignment: .leading)
            })
    }
}

@available(iOS 17.0, *)
private extension POSPreSearchView {
    enum Localization {
        static let popularProductsTitle = NSLocalizedString(
            "pos.itemsearch.before.search.popularProducts.title",
            value: "Popular products",
            comment: "Title for the list of popular products shown before a search term is typed in POS")

        static let preSearchEmptyListText = NSLocalizedString(
            "pos.itemsearch.before.search.emptyListText",
            value: "Search your store",
            comment: "Text shown when there's nothing to show before a search term is typed in POS")
    }
}
