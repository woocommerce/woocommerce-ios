import SwiftUI

/// View for searching and selecting target locations for a Blaze campaign.
struct BlazeTargetLocationPickerView: View {

    @ObservedObject private var viewModel: BlazeTargetLocationPickerViewModel

    @FocusState private var isSearchMode

    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetLocationPickerViewModel,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchHeader(text: $viewModel.searchQuery,
                             placeholder: Localization.searchBarPlaceholderText,
                             isFocused: _isSearchMode,
                             customizations: .init(showsCancelButton: true))
                if isSearchMode {
                    searchView
                } else {
                    pickerView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButtonTitle, action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.saveButtonTitle) {
                        viewModel.confirmSelection()
                        onDismiss()
                    }
                    .disabled(viewModel.shouldDisableSaveButton)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private extension BlazeTargetLocationPickerView {
    @ViewBuilder
    var searchView: some View {
        switch (viewModel.searchQuery.isEmpty, viewModel.isSearching, viewModel.searchResults.isEmpty) {
        case (true, _, _):
            emptyView
        case (false, true, true):
            loadingView
        case (false, false, true):
            noResultView
        case (false, _, false):
            resultList
        }
    }

    var pickerView: some View {
        List {
            Section {
                Text(Localization.everywhere)
            } footer: {
                Text(Localization.searchHint)
            }
            Section {
                ForEach(Array(viewModel.selectedLocations ?? [])) { item in
                    Text(item.name)
                }
            }
        }
        .listStyle(.grouped)
    }

    var emptyView: some View {
        VStack(spacing: Layout.contentSpacing) {
            Spacer()
            Image(uiImage: .searchImage)
            Text(Localization.hintMessage)
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
        List {
            ForEach(viewModel.searchResults) { item in
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
                    isSearchMode = false
                    viewModel.selectItem(item)
                }
            }
            Spacer()
        }
        .listStyle(.plain)
    }
}

private extension BlazeTargetLocationPickerView {
    enum Layout {
        static let contentSpacing: CGFloat = 16
    }
    enum Localization {
        static let title = NSLocalizedString(
            "blazeTargetLocationPickerView.title",
            value: "Location",
            comment: "Title of the target language picker view for Blaze campaign creation"
        )
        static let allTitle = NSLocalizedString(
            "blazeTargetLocationPickerView.allTitle",
            value: "Everywhere",
            comment: "Title of the row to select all target location for Blaze campaign creation"
        )
        static let searchBarPlaceholderText = NSLocalizedString(
            "blazeTargetLocationPickerView.search",
            value: "Search",
            comment: "Placeholder in the search bar of the target location picker for campaign creation"
        )
        static let cancelButtonTitle = NSLocalizedString(
            "blazeTargetLocationPickerView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the target location picker for campaign creation"
        )
        static let saveButtonTitle = NSLocalizedString(
            "blazeTargetLocationPickerView.save",
            value: "Save",
            comment: "Button to save the selections on the target location picker for campaign creation"
        )
        static let hintMessage = NSLocalizedString(
            "blazeTargetLocationPickerView.hintMessage",
            value: "Start typing country, state or city to see available options",
            comment: "Hint message to enter search query on the target location picker for campaign creation"
        )
        static let longerQuery = NSLocalizedString(
            "blazeTargetLocationPickerView.longerQuery",
            value: "Please enter at least 3 characters to start searching.",
            comment: "Message indicating the minimum length for search queries on the target location picker for campaign creation"
        )
        static let noResult = NSLocalizedString(
            "blazeTargetLocationPickerView.noResult",
            value: "No location found.\nPlease try again.",
            comment: "Message indicating no search result on the target location picker for campaign creation"
        )
        static let everywhere = NSLocalizedString(
            "blazeTargetLocationPickerView.everywhere",
            value: "Everywhere",
            comment: "Option to remove any limit on the target location picker for campaign creation"
        )
        static let searchHint = NSLocalizedString(
            "blazeTargetLocationPickerView.searchHint",
            value: "Or select specific locations by entering queries in the search box",
            comment: "Suggestion for searching for specific locations on the target location picker for campaign creation"
        )
    }
}

#Preview {
    BlazeTargetLocationPickerView(viewModel: .init(siteID: 123) { _ in }) {}
}
