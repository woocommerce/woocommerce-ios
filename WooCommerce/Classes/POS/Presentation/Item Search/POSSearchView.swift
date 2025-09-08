import SwiftUI
import enum Yosemite.POSItemType
import enum Yosemite.POSItem

/// Protocol defining search capabilities for POS items
protocol POSSearchable {
    var searchFieldPlaceholder: String { get }
    /// Recent search history for the current item type
    var searchHistory: [String] { get }

    /// Called when a search should be performed
    /// - Parameter term: The search term to use
    func performSearch(term: String) async

    func clearSearchResults()
}

/// A reusable search field view for POS items
struct POSSearchField: View {
    @Environment(\.keyboardObserver) private var keyboardObserver

    @Binding private var searchTerm: String
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchTask: Task<Void, Never>?
    @State private var didFinishSearch = true
    @ScaledMetric private var searchFieldHeight: CGFloat = 56.0

    private let searchable: any POSSearchable
    private let onBack: () -> Void

    init(searchTerm: Binding<String>,
         searchable: any POSSearchable,
         onBack: @escaping () -> Void) {
        self._searchTerm = searchTerm
        self.searchable = searchable
        self.onBack = onBack
    }

    var body: some View {
        HStack(spacing: POSSpacing.small) {
            POSPageHeaderBackButton(configuration: .init(state: .enabled, action: {
                searchTerm = ""
                onBack()
                isSearchFieldFocused = false
            }))

            TextField(text: $searchTerm) {
                Text(searchable.searchFieldPlaceholder)
            }
            .textFieldStyle(POSSearchTextFieldStyle(focused: isSearchFieldFocused,
                                                    searchTerm: $searchTerm))
            .font(.posBodyLargeBold)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($isSearchFieldFocused)
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
                        try? await Task.sleep(nanoseconds: 500 * NSEC_PER_MSEC)
                    } else {
                        searchable.clearSearchResults()
                    }

                    guard !Task.isCancelled else { return }

                    guard newValue.isNotEmpty else {
                        didFinishSearch = true
                        return
                    }

                    didFinishSearch = false
                    await searchable.performSearch(term: newValue)

                    if !Task.isCancelled {
                        didFinishSearch = true
                    }
                }
            }
        }
        .onChange(of: keyboardObserver.isKeyboardVisible) { _, isVisible in
            guard isVisible == false else { return }
            ServiceLocator.analytics.track(.pointOfSaleKeyboardDismissedInSearch)
        }
        .onAppear {
            isSearchFieldFocused = true
        }
    }
}

/// A reusable search content view for POS items
struct POSSearchContentView<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let searchable: any POSSearchable
    private let itemListType: ItemListType
    @Binding private var searchTerm: String
    private let content: (Bool) -> Content

    init(searchable: any POSSearchable,
         itemListType: ItemListType,
         searchTerm: Binding<String>,
         @ViewBuilder content: @escaping (Bool) -> Content) {
        self.searchable = searchable
        self.itemListType = itemListType
        self._searchTerm = searchTerm
        self.content = content
    }

    var body: some View {
        if searchTerm.isEmpty {
            preSearchView
                .background(Color.posSurface)
        } else {
            content(true)
                .background(Color.posSurface)
        }
    }

    @ViewBuilder
    private var preSearchView: some View {
        POSPreSearchView(savedSearches: searchable.searchHistory,
                         onSearchSelected: { selectedSearchTerm in
            searchTerm = selectedSearchTerm
            ServiceLocator.analytics.track(
                event: .PointOfSale.preSearchRecentTermTapped(itemListType: itemListType))
        },
                         itemListType: itemListType
        )
    }
}

// MARK: - Localization
extension POSItemType {
    var searchFieldLabel: String {
        switch self {
        case .product:
            return Localization.productsSearchFieldLabel
        case .coupon:
            return Localization.couponsSearchFieldLabel
        default:
            return Localization.defaultSearchFieldLabel
        }
    }

    enum Localization {
        static let productsSearchFieldLabel = NSLocalizedString(
            "pos.itemListView.products.searchField.label.1",
            value: "Search products",
            comment: "Label/placeholder text for the search field for Products in Point of Sale."
        )

        static let couponsSearchFieldLabel = NSLocalizedString(
            "pos.itemListView.coupons.searchField.label",
            value: "Search coupons",
            comment: "Label/placeholder text for the search field for Coupons in Point of Sale."
        )

        static let defaultSearchFieldLabel = NSLocalizedString(
            "pos.itemListView.searchField.label",
            value: "Search",
            comment: "Fallback label/placeholder text for the search field in Point of Sale."
        )
    }
}
