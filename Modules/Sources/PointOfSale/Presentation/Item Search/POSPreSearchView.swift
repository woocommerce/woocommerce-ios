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
    let onItemSelected: () -> Void

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
            onItemSelected: onItemSelected,
            headerView: {
                VStack(alignment: .leading, spacing: metrics.spacing.none) {
                    recentSearchesSection(bottomPadding: metrics.padding.large)

                    // No bottom padding: ItemList already spaces its header from the first card.
                    sectionHeader(Localization.popularProductsTitle)
                }
            })
    }

    @ViewBuilder private var recentSearchesOnly: some View {
        if savedSearches.isNotEmpty {
            VStack(alignment: .leading, spacing: metrics.spacing.none) {
                recentSearchesSection(bottomPadding: metrics.padding.medium)

                Spacer()
            }
            .padding(.horizontal, metrics.padding.medium)
        } else {
            POSListEmptyView(viewModel: POSCouponPreSearchEmptyViewModel())
        }
    }

    @ViewBuilder private func recentSearchesSection(bottomPadding: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: metrics.spacing.none) {
            if savedSearches.isNotEmpty {
                sectionHeader(Localization.recentSearchesTitle)

                recentSearches
                    .padding(.bottom, bottomPadding)
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
            .padding(.top, metrics.padding.medium)
        }
        // The chip shadow is larger than this padding and the chips start at the leading edge.
        .scrollClipDisabled()
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
    }
}

struct POSCouponPreSearchEmptyViewModel: POSListEmptyViewModelProtocol {
    var title: String { Localization.title }
    var subtitle: String { Localization.subtitle }
    var buttonTitle: String? { nil }
    var icon: Image { PointOfSaleAssets.coupons.decorativeImage }
}

private extension POSCouponPreSearchEmptyViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.itemsearch.before.search.coupons.emptyTitle",
            value: "Find a coupon",
            comment: "Title shown on the coupon search screen in POS before a search term is typed, when there are no recent searches")
        static let subtitle = NSLocalizedString(
            "pos.itemsearch.before.search.coupons.emptySubtitle",
            value: "Type a coupon code to search.",
            comment: "Subtitle shown on the coupon search screen in POS before a search term is typed, when there are no recent searches")
    }
}
