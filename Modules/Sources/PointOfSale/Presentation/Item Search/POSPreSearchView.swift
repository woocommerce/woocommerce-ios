import SwiftUI
import enum Yosemite.POSItem
import WooFoundation

struct POSPreSearchView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @ScaledMetric private var chipHeight: CGFloat = 56.0

    let savedSearches: [String]
    let onSearchSelected: (String) -> Void

    let itemListType: ItemListType

    var body: some View {
        switch itemListType {
        case .products:
            recentSearchesAndPopularProducts
        case .coupons:
            recentSearchesOnly
        }
    }

    @ViewBuilder private var recentSearchesAndPopularProducts: some View {
        ItemList(
            itemsController: posModel.popularPurchasableItemsController,
            node: .root,
            itemActionHandler: StandardPOSItemActionHandler(
                posModel: posModel,
                sourceView: .init(itemListType: itemListType),
                sourceViewType: .preSearch,
                analytics: analytics
            ),
            headerView: {
                VStack(alignment: .leading, spacing: metrics.spacing.none) {
                    recentSearchesSection

                    sectionHeader(Localization.popularProductsTitle)
                        .padding(.bottom, metrics.padding.medium)
                }
            })
    }

    @ViewBuilder private var recentSearchesOnly: some View {
        VStack(alignment: .leading, spacing: metrics.spacing.none) {
            if savedSearches.isNotEmpty {
                recentSearchesSection

                Spacer()
            } else {
                Text(Localization.preSearchEmptyListText)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurface)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.top, metrics.padding.medium)
            }
        }
        .padding(.horizontal, metrics.padding.medium)
    }

    @ViewBuilder private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: metrics.spacing.none) {
            if savedSearches.isNotEmpty {
                sectionHeader(Localization.recentSearchesTitle)

                recentSearches
            }
        }
    }

    @ViewBuilder private var recentSearches: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: metrics.spacing.small) {
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
                        .padding(.horizontal, metrics.padding.medium)
                        .padding(.vertical, metrics.padding.small)
                        .frame(height: chipHeight)
                        .background(Color.posSurfaceBright)
                        .cornerRadius(POSCornerRadiusStyle.medium.value)
                        .posShadow(.medium, cornerRadius: POSCornerRadiusStyle.medium.value)
                    }
                }
            }
            .padding(.vertical, metrics.padding.medium) // Use padding not VStack spacing so the Chip shadows aren't clipped
        }
    }

    @ViewBuilder private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(POSFontStyle.posBodyMediumBold)
            .foregroundColor(.posOnSurface)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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
