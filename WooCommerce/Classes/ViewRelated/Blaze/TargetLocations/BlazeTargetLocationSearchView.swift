import SwiftUI

/// View for the search mode of the `BlazeTargetLocationPickerView`
struct BlazeTargetLocationSearchView: View {
    @Environment(\.isSearching) private var isSearching
    @Environment(\.dismissSearch) private var dismissSearch

    @ObservedObject private var viewModel: BlazeTargetLocationPickerViewModel

    init(viewModel: BlazeTargetLocationPickerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if isSearching {
            searchView
        } else {
            pickerView
        }
    }
}

private extension BlazeTargetLocationSearchView {
    @ViewBuilder
    var searchView: some View {
        if viewModel.searchQuery.isEmpty {
            emptyView
        } else if viewModel.fetchInProgress {
            loadingView
        } else if viewModel.searchResults.isEmpty {
            noResultView
        } else {
            resultList
        }
    }

    var pickerView: some View {
        MultiSelectionList(headerMessage: Localization.headerMessage,
                           allOptionsTitle: Localization.allTitle,
                           allOptionsFooter: Localization.searchHint,
                           itemsSectionHeader: Localization.specificLocationHeader,
                           contents: viewModel.selectedSearchResults,
                           contentKeyPath: \.name,
                           selectedItems: $viewModel.selectedLocations,
                           autoSelectAll: false)
    }

    var emptyView: some View {
        VStack(spacing: Layout.contentSpacing) {
            Spacer()
            Image(uiImage: .searchImage)
            Text(Localization.searchViewHintMessage)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    var noResultView: some View {
        VStack(spacing: Layout.contentSpacing) {
            Spacer()
            Image(uiImage: viewModel.searchQuery.count >= 3 ? .searchNoResultImage : .searchImage)
            Text(viewModel.searchQuery.count >= 3 ? Localization.noResult : Localization.longerQuery)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    var loadingView: some View {
        VStack {
            Spacer()
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
            Spacer()
        }
    }

    var resultList: some View {
        List(viewModel.searchResults) { item in
            VStack(alignment: .leading) {
                HStack {
                    Text(item.name)
                    Spacer()
                    Text(item.type)
                        .foregroundColor(.secondary)
                        .captionStyle()
                }
                Text(item.allParentLocationNames.joined(separator: ", "))
                    .foregroundColor(.secondary)
                    .captionStyle()
                    .renderedIf(item.allParentLocationNames.isNotEmpty)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.addOptionFromSearchResult(item)
                dismissSearch()
            }
        }
        .listStyle(.plain)
    }
}

private extension BlazeTargetLocationSearchView {
    enum Layout {
        static let contentSpacing: CGFloat = 16
    }
    enum Localization {
        static let allTitle = NSLocalizedString(
            "blazeTargetLocationSearchView.allTitle",
            value: "Everywhere",
            comment: "Title of the row to select all target location for Blaze campaign creation"
        )
        static let searchViewHintMessage = NSLocalizedString(
            "blazeTargetLocationSearchView.searchViewHintMessage",
            value: "Start typing country, state or city to see available options",
            comment: "Hint message to enter search query on the target location picker for campaign creation"
        )
        static let longerQuery = NSLocalizedString(
            "blazeTargetLocationSearchView.longerQuery",
            value: "Please enter at least 3 characters to start searching.",
            comment: "Message indicating the minimum length for search queries on the target location picker for campaign creation"
        )
        static let noResult = NSLocalizedString(
            "blazeTargetLocationSearchView.noResult",
            value: "No location found.\nPlease try again.",
            comment: "Message indicating no search result on the target location picker for campaign creation"
        )
        static let searchHint = NSLocalizedString(
            "blazeTargetLocationSearchView.searchHint",
            value: "Or choose specific locations by typing what you’re looking for in the search box.",
            comment: "Suggestion for searching for specific locations on the target location picker for campaign creation"
        )
        static let headerMessage = NSLocalizedString(
            "blazeTargetLocationSearchView.headerMessage",
            value: "Choose target locations",
            comment: "Header message on the target location picker for campaign creation"
        )
        static let specificLocationHeader = NSLocalizedString(
            "blazeTargetLocationSearchView.specificLocationHeader",
            value: "Specific locations",
            comment: "Header for the Specific Locations section on the target location picker for campaign creation"
        )
    }
}

#Preview {
    BlazeTargetLocationSearchView(viewModel: .init(siteID: 123, onCompletion: { _ in }))
}
