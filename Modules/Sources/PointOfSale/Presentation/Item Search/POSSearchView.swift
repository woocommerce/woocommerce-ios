import SwiftUI
import enum Yosemite.POSItemType
import enum Yosemite.POSItem
import enum Yosemite.SearchDebounceStrategy

/// Protocol defining search capabilities for POS items
protocol POSSearchable {
    var searchFieldPlaceholder: String { get }
    /// Recent search history for the current item type
    var searchHistory: [String] { get }
    /// The debouncing strategy currently active based on the controller's current state
    var currentDebounceStrategy: SearchDebounceStrategy { get }
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
                handleSearchTermChange(newValue)
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

// MARK: - Search Handling
private extension POSSearchField {
    func handleSearchTermChange(_ newValue: String) {
        searchTask?.cancel()

        let debounceStrategy = selectDebounceStrategy(for: newValue)

        searchTask = Task {
            await executeSearchWithStrategy(debounceStrategy, searchTerm: newValue)
        }
    }

    func selectDebounceStrategy(for searchTerm: String) -> SearchDebounceStrategy {
        // Use searchDebounceStrategy for non-empty search terms (actual searches),
        // and currentDebounceStrategy for empty terms (returning to popular products).
        searchTerm.isNotEmpty ? searchable.searchDebounceStrategy : searchable.currentDebounceStrategy
    }

    func executeSearchWithStrategy(_ strategy: SearchDebounceStrategy, searchTerm: String) async {
        switch strategy {
        case .smart(let duration, let loadingDelayThreshold):
            await executeSmartDebouncedSearch(duration: duration, loadingDelayThreshold: loadingDelayThreshold, searchTerm: searchTerm)
        case .simple(let duration, let loadingDelayThreshold):
            await executeSimpleDebouncedSearch(duration: duration, loadingDelayThreshold: loadingDelayThreshold, searchTerm: searchTerm)
        case .immediate:
            await executeImmediateSearch(searchTerm: searchTerm)
        }
    }

    func executeSmartDebouncedSearch(duration: UInt64, loadingDelayThreshold: UInt64?, searchTerm: String) async {
        // Smart debouncing: Don't debounce first keystroke, but debounce subsequent keystrokes
        // The loading indicator behavior depends on whether there's a threshold:
        // - With threshold: Show loading after threshold if search hasn't completed (prevents flicker)
        // - Without threshold: Show loading immediately (responsive feel)

        let isFirstKeystroke = didFinishSearch

        guard searchTerm.isNotEmpty else {
            didFinishSearch = true
            return
        }

        // Handle loading indicators for first keystroke
        let loadingTask = isFirstKeystroke ? startLoadingIndicatorTask(threshold: loadingDelayThreshold) : nil

        // Debounce subsequent keystrokes
        if !isFirstKeystroke {
            try? await Task.sleep(nanoseconds: duration)
        }

        guard !Task.isCancelled else {
            loadingTask?.cancel()
            return
        }

        await performSearchAndTrackCompletion(searchTerm: searchTerm)
        loadingTask?.cancel()
    }

    func executeSimpleDebouncedSearch(duration: UInt64,
                                      loadingDelayThreshold: UInt64?,
                                      searchTerm: String) async {
        // Simple debouncing: Always debounce every keystroke
        try? await Task.sleep(nanoseconds: duration)

        guard !Task.isCancelled else { return }
        guard searchTerm.isNotEmpty else {
            didFinishSearch = true
            return
        }

        didFinishSearch = false

        if let threshold = loadingDelayThreshold {
            await performSearchWithDelayedLoading(searchTerm: searchTerm, threshold: threshold)
        } else {
            searchable.clearSearchResults()
            await searchable.performSearch(term: searchTerm)
        }

        if !Task.isCancelled {
            didFinishSearch = true
        }
    }

    func executeImmediateSearch(searchTerm: String) async {
        guard !Task.isCancelled else { return }
        guard searchTerm.isNotEmpty else {
            didFinishSearch = true
            return
        }

        await performSearchAndTrackCompletion(searchTerm: searchTerm)
    }

    func startLoadingIndicatorTask(threshold: UInt64?) -> Task<Void, Never>? {
        if let threshold {
            // With threshold: delay showing loading to prevent flicker for fast searches
            return Task { @MainActor in
                try? await Task.sleep(nanoseconds: threshold)
                if !Task.isCancelled {
                    searchable.clearSearchResults()
                }
            }
        } else {
            // No threshold - show loading immediately for responsive feel
            searchable.clearSearchResults()
            return nil
        }
    }

    func performSearchWithDelayedLoading(searchTerm: String, threshold: UInt64) async {
        // Create a loading task that shows indicators after threshold
        let loadingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: threshold)
            if !Task.isCancelled {
                searchable.clearSearchResults()
            }
        }

        await searchable.performSearch(term: searchTerm)

        // Cancel loading task if search completed before threshold
        loadingTask.cancel()
    }

    private func performSearchAndTrackCompletion(searchTerm: String) async {
        didFinishSearch = false
        await searchable.performSearch(term: searchTerm)

        if !Task.isCancelled {
            didFinishSearch = true
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
