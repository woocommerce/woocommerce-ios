import SwiftUI
import enum Yosemite.POSItem

@available(iOS 17.0, *)
struct POSPreSearchView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @ScaledMetric private var chipHeight: CGFloat = 56.0

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
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    if savedSearches.isNotEmpty {
                        // Search history
                        sectionHeader(Localization.recentSearchesTitle)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: POSSpacing.small) {
                                ForEach(savedSearches, id: \.self) { searchTerm in
                                    Button(action: {
                                        onSearchSelected(searchTerm)
                                    }) {
                                        Label {
                                            Text(searchTerm)
                                                .font(.posBodyLargeRegular())
                                                .foregroundColor(.posOnSurface)
                                        } icon: {
                                            Image(systemName: "magnifyingglass")
                                                .font(.posBodyMediumRegular())
                                                .foregroundColor(.posOnSurfaceVariantHighest)
                                        }
                                        .padding(.horizontal, POSPadding.medium)
                                        .padding(.vertical, POSPadding.small)
                                        .frame(height: chipHeight)
                                        .background(Color.posSurfaceBright)
                                        .cornerRadius(POSCornerRadiusStyle.medium.value)
                                        .posShadow(.medium)
                                    }
                                }
                            }
                        }
                    }

                    sectionHeader(Localization.popularProductsTitle)
                        .padding(.bottom, POSPadding.medium)
                }
            })
    }

    @ViewBuilder private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(POSFontStyle.posBodyMediumBold)
            .foregroundColor(.posOnSurface)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 17.0, *)
private extension POSPreSearchView {
    enum Localization {
        static let recentSearchesTitle = NSLocalizedString(
            "pos.itemsearch.before.search.recentSearches.title",
            value: "Recent searches",
            comment: "Title for the list of recent searches shown before a search term is typed in POS")

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
