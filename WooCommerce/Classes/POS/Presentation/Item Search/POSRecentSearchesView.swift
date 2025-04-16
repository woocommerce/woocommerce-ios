import SwiftUI

@available(iOS 17.0, *)
struct POSRecentSearchesView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let savedSearches: [String]
    let onSearchSelected: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                if savedSearches.isEmpty {
                    Text(Localization.recentSearchesEmptyListText)
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
                        alignment: .leading,
                        spacing: POSSpacing.medium
                    ) {
                        ForEach(savedSearches, id: \.self) { searchTerm in
                            RecentSearchCard(searchTerm: searchTerm, onSearchSelected: onSearchSelected)
                        }
                    }
                    .padding(.horizontal, POSPadding.medium)
                }
            }
            .padding(.bottom, POSPadding.medium)
        }
    }

    private var gridColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            // Single column for accessibility sizes
            return [GridItem(.flexible(), spacing: POSSpacing.medium)]
        } else {
            // Two equal columns for normal sizes
            return [
                GridItem(.flexible(), spacing: POSSpacing.medium),
                GridItem(.flexible(), spacing: POSSpacing.medium)
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
            "pos.itemsearch.before.search.recentSearches.emptyListText",
            value: "No recent searches",
            comment: "Text shown when there's nothing to show before a search term is typed in POS")

    }
}

private struct RecentSearchCard: View {
    let searchTerm: String
    let onSearchSelected: (String) -> Void

    var body: some View {
        Button(action: {
            onSearchSelected(searchTerm)
        }) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .accessibilityHidden(true)
                    .foregroundColor(.posOnSurfaceVariantLowest)
                Text(searchTerm)
                    .lineLimit(1)
                    .font(.posBodyMediumRegular())
                Spacer()
            }
            .padding(POSPadding.medium)
            .background(Color(.systemBackground))
            .cornerRadius(POSCornerRadiusStyle.medium.value)
            .posShadow(.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
