import SwiftUI
import enum Yosemite.POSItemType
import enum Yosemite.POSItem
import enum Yosemite.SearchDebounceStrategy

/// Protocol defining search capabilities for POS items
protocol POSSearchable {
    var searchFieldPlaceholder: String { get }
    /// Recent search history for the current item type
    var searchHistory: [String] { get }
    /// The debouncing strategy to use for search input
    var debounceStrategy: SearchDebounceStrategy { get }
    /// The debouncing strategy that will be used when performing a search (may differ from current strategy)
    var searchDebounceStrategy: SearchDebounceStrategy { get }

    /// Called when a search should be performed
    /// - Parameter term: The search term to use
    func performSearch(term: String) async

    func clearSearchResults()
}

/// A reusable search field view for POS items
struct POSSearchField: View {
    @Environment(\.keyboardObserver) private var keyboardObserver
    @Environment(\.posAnalytics) private var analytics

    @Binding private var searchTerm: String
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchTask: Task<Void, Never>?
    @State private var didFinishSearch = true

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
            .posSearchTextFieldStyle(focused: isSearchFieldFocused,
                                     searchTerm: $searchTerm)
            .font(.posBodyLargeBold)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($isSearchFieldFocused)
            .onChange(of: searchTerm) { oldValue, newValue in
                // Cancel any ongoing search
                searchTask?.cancel()

                // Capture the debounce strategy synchronously BEFORE creating the task.
                // Use searchDebounceStrategy for non-empty search terms (actual searches),
                // and debounceStrategy for empty terms (returning to popular products).
                let debounceStrategy = newValue.isNotEmpty ? searchable.searchDebounceStrategy : searchable.debounceStrategy

                searchTask = Task {
                    // Apply debouncing based on the strategy captured at the start
                    switch debounceStrategy {
                    case .smart(let duration, let loadingDelayThreshold):
                        // Smart debouncing: Don't debounce first keystroke, but debounce subsequent keystrokes
                        // The loading indicator behavior depends on whether there's a threshold:
                        // - With threshold: Show loading after threshold if search hasn't completed (prevents flicker)
                        // - Without threshold: Show loading immediately (responsive feel)

                        let shouldDebounceNextSearchRequest = !didFinishSearch

                        // Early exit if search term is empty
                        guard newValue.isNotEmpty else {
                            didFinishSearch = true
                            return
                        }

                        // Start loading indicator task if we have a threshold and this is first keystroke
                        let loadingTask: Task<Void, Never>?
                        if !shouldDebounceNextSearchRequest {
                            // First keystroke - handle loading indicators
                            if let threshold = loadingDelayThreshold {
                                // With threshold: delay showing loading to prevent flicker for fast searches
                                loadingTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: threshold)
                                    if !Task.isCancelled {
                                        searchable.clearSearchResults()
                                    }
                                }
                            } else {
                                // No threshold - show loading immediately for responsive feel
                                searchable.clearSearchResults()
                                loadingTask = nil
                            }
                        } else {
                            // Subsequent keystrokes - loading already showing from previous search
                            loadingTask = nil
                        }

                        if shouldDebounceNextSearchRequest {
                            try? await Task.sleep(nanoseconds: duration)
                        }

                        // Now perform the search (common code for both and subsequent keystrokes)
                        guard !Task.isCancelled else {
                            loadingTask?.cancel()
                            return
                        }

                        didFinishSearch = false
                        await searchable.performSearch(term: newValue)

                        // Cancel loading task if search completed (only relevant for first keystroke with threshold)
                        loadingTask?.cancel()

                        if !Task.isCancelled {
                            didFinishSearch = true
                        }
                        return

                    case .simple(let duration, let loadingDelayThreshold):
                        // Simple debouncing: Always debounce
                        try? await Task.sleep(nanoseconds: duration)

                        guard !Task.isCancelled else { return }
                        guard newValue.isNotEmpty else {
                            didFinishSearch = true
                            return
                        }

                        didFinishSearch = false

                        if let threshold = loadingDelayThreshold {
                            // Delay showing loading indicators to avoid flicker for fast queries
                            // Create a loading task that shows indicators after threshold
                            let loadingTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: threshold)
                                // Only show loading if not cancelled
                                if !Task.isCancelled {
                                    searchable.clearSearchResults()
                                }
                            }

                            // Perform the search
                            await searchable.performSearch(term: newValue)

                            // Cancel loading task if search completed before threshold
                            loadingTask.cancel()
                        } else {
                            // No loading delay threshold - show loading immediately
                            searchable.clearSearchResults()
                            await searchable.performSearch(term: newValue)
                        }

                        if !Task.isCancelled {
                            didFinishSearch = true
                        }
                        return

                    case .immediate:
                        // No debouncing
                        break
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
            analytics.track(.pointOfSaleKeyboardDismissedInSearch)
        }
        .onAppear {
            isSearchFieldFocused = true
        }
    }
}

/// A reusable search content view for POS items
struct POSSearchContentView<Content: View>: View {
    @Environment(\.posAnalytics) private var analytics

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
            analytics.track(event: .PointOfSale.preSearchRecentTermTapped(itemListType: itemListType))
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
