import SwiftUI

@available(iOS 17.0, *)
struct POSRecentSearchesView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(\.keyboardObserver) private var keyboardObserver

    let savedSearches: [String]
    let onSearchSelected: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                if savedSearches.isEmpty {
                    Text(Localization.recentSearchesEmptyListText)
                        .font(.posBodyLargeRegular())
                        .foregroundColor(.posOnSurface)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, POSPadding.medium)
                } else {
                    // Column header
                    Label {
                        Text(Localization.recentSearchesTitle)
                            .font(POSFontStyle.posBodyMediumBold)
                            .foregroundColor(.posOnSurface)
                            .accessibilityAddTraits(.isHeader)
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.posOnSurface)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, POSPadding.medium)
                    .padding(.top, POSPadding.medium)

                    // Grid of saved searches
                    LazyVGrid(
                        columns: gridColumns,
                        alignment: .leading
                    ) {
                        ForEach(savedSearches, id: \.self) { searchTerm in
                            RecentSearchCard(searchTerm: searchTerm, onSearchSelected: onSearchSelected)
                        }
                    }
                    .padding(.horizontal, POSPadding.medium)
                }
            }
            .padding(.bottom, keyboardObserver.isFullSizeKeyboardVisible ? POSPadding.medium : floatingControlAreaSize.height + POSPadding.medium)
        }
    }

    private var gridColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            // Single column for accessibility sizes
            return [GridItem(.flexible(), spacing: Constants.cardSpacing)]
        } else {
            // Two equal columns for normal sizes
            return [
                GridItem(.flexible(), spacing: Constants.cardSpacing),
                GridItem(.flexible(), spacing: Constants.cardSpacing)
            ]
        }
    }
}

@available(iOS 17.0, *)
private extension POSRecentSearchesView {
    enum Localization {
        static let recentSearchesTitle = NSLocalizedString(
            "pos.itemsearch.before.search.recentSearches.title",
            value: "Recent searches",
            comment: "Title for the list of recent searches shown before a search term is typed in POS")

        static let recentSearchesEmptyListText = NSLocalizedString(
            "pos.itemsearch.before.search.recentSearches.emptyListText.1",
            value: "Search your store",
            comment: "Text shown when there's nothing to show before a search term is typed in POS")
    }

    enum Constants {
        static let cardSpacing: CGFloat = POSSpacing.small
    }
}

struct RecentSearchCard: View {
    @ScaledMetric private var scale: CGFloat = 1.0

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    let searchTerm: String
    let onSearchSelected: (String) -> Void

    var body: some View {
        Button(action: {
            onSearchSelected(searchTerm)
        }) {
            HStack(spacing: Constants.cardSpacing) {
                searchIcon
                    .frame(width: dimension, height: dimension)

                Text(searchTerm)
                    .lineLimit(2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)
                    .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
                    .padding(.vertical, Constants.verticalTextPadding * (1 / scale))

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, idealHeight: dimension)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
    }

    private var searchIcon: some View {
        Rectangle()
            .foregroundColor(.posSurfaceDim)
            .overlay {
                Image(systemName: "magnifyingglass")
                    .font(.posButtonSymbolLarge)
                    .foregroundColor(.posOnSurfaceVariantLowest)
            }
    }
}

private extension RecentSearchCard {
    typealias Constants = PointOfSaleItemListCardConstants
}
