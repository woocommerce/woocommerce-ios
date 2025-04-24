import SwiftUI
import enum Yosemite.POSItemType

/// Protocol defining search capabilities for POS items
@available(iOS 17.0, *)
protocol POSSearchable {
    /// The type of items being searched
    var itemType: POSItemType { get }

    /// Recent search history for the current item type
    var searchHistory: [String] { get }

    /// Called when a search should be performed
    /// - Parameter term: The search term to use
    func performSearch(term: String)

    /// Called when a recent search is selected
    /// - Parameter term: The search term that was selected
    func selectRecentSearch(term: String)
}

/// A reusable search view component for POS items
@available(iOS 17.0, *)
struct POSSearchView<Content: View>: View {
    @Environment(\.keyboardObserver) private var keyboardObserver

    @Binding var searchTerm: String
    @Binding var isSearching: Bool
    @State private var searchTask: Task<Void, Never>?
    @State private var didFinishSearch = true

    @FocusState private var isSearchFieldFocused: Bool

    private let searchable: any POSSearchable
    private let content: () -> Content

    private typealias Localization = POSSearchViewLocalization

    init(isSearching: Binding<Bool>,
         searchTerm: Binding<String>,
         searchable: any POSSearchable,
         @ViewBuilder content: @escaping () -> Content) {
        self._isSearching = isSearching
        self._searchTerm = searchTerm
        self.searchable = searchable
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            if searchTerm.isEmpty {
                POSRecentSearchesView(
                    savedSearches: searchable.searchHistory,
                    onSearchSelected: { search in
                        searchTerm = search
                        searchable.selectRecentSearch(term: search)
                    }
                )
                .background(Color.posSurface)
            } else {
                content()
            }
        }
        .background(Color.posSurface)
        .onChange(of: keyboardObserver.isKeyboardVisible) { _, isVisible in
            guard isVisible == false else { return }
            ServiceLocator.analytics.track(.pointOfSaleKeyboardDismissedInSearch)
        }
        .onChange(of: searchTerm) { oldValue, newValue in
            // The debouncing logic is a little tricky, because the loading state is held in the controller.
            // Arguably, we should use view state `isSearching` for this, so the UI is independent of the request timing.

            // As the user types, we don't want to send every keystroke to the remote, so we debounce the requests.
            // However, we don't want to debounce the first keystroke of a new search, so that the loading
            // state shows immediately and the UI feels responsive.

            // So, if the last search was finished, we don't debounce the first character. If it didn't
            // finish i.e. it is still ongoing, we debounce the next keystrokes by 300ms. In either case,
            // the ongoing search is redundant now there's a new search term, so we cancel it.
            let shouldDebounceNextSearchRequest = !didFinishSearch
            searchTask?.cancel()

            searchTask = Task {
                if shouldDebounceNextSearchRequest {
                    try? await Task.sleep(nanoseconds: 300 * NSEC_PER_MSEC)
                }

                guard !Task.isCancelled else { return }

                guard newValue.isNotEmpty else {
                    didFinishSearch = true
                    return
                }

                didFinishSearch = false
                searchable.performSearch(term: newValue)

                if !Task.isCancelled {
                    didFinishSearch = true
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: POSSpacing.small) {
            Button {
                withAnimation {
                    clearSearch()
                    isSearchFieldFocused = false
                    isSearching = false
                }
            } label: {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.posOnSurface)
                    .font(.posButtonSymbolLarge)
            }

            TextField(text: $searchTerm) {
                Text(searchable.itemType.searchFieldLabel)
            }
            .font(POSFontStyle.posBodyLargeRegular())
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($isSearchFieldFocused)

            Button {
                clearSearch()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .accessibilityLabel(Localization.searchFieldClearButtonAccessibilityLabel)
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .font(.posButtonSymbolSmall)
            }
            .transition(.opacity)
            .renderedIf(searchTerm.isNotEmpty)
        }
    }

    private func clearSearch() {
        searchTerm = ""
    }
}

// MARK: - Localization
@available(iOS 17.0, *)
private enum POSSearchViewLocalization {
    static let searchFieldClearButtonAccessibilityLabel = NSLocalizedString(
        "pos.searchview.searchField.clearButton.accessibilityLabel",
        value: "Clear Search",
        comment: "Accessibility label for the clear button in the Point of Sale search screen."
    )
}

private extension POSItemType {
    var searchFieldLabel: String {
        switch self {
        case .product:
            return Localization.productsSearchFieldLabel
        default:
            return Localization.defaultSearchFieldLabel
        }
    }

    enum Localization {
        static let productsSearchFieldLabel = NSLocalizedString(
            "pos.itemListView.products.searchField.label",
            value: "Search Products",
            comment: "Label/placeholder text for the search field for Products in Point of Sale."
        )

        static let defaultSearchFieldLabel = NSLocalizedString(
            "pos.itemListView.searchField.label",
            value: "Search",
            comment: "Fallback label/placeholder text for the search field in Point of Sale."
        )
    }
}
