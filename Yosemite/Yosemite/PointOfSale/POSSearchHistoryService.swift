import Foundation

/// Service for managing search history in the Point of Sale
@available(iOS 17.0, *)
public final class POSSearchHistoryService {
    private let maxHistorySize: Int
    private var searchHistory: [POSItemType: [String]] = [:]

    /// Initializes a new search history service
    /// - Parameter maxHistorySize: Maximum number of search terms to keep in history per item type
    public init(maxHistorySize: Int = 10) {
        self.maxHistorySize = maxHistorySize
    }

    /// Saves a successful search term to the history
    /// - Parameters:
    ///   - term: The search term to save
    ///   - itemType: The type of item being searched
    public func saveSuccessfulSearch(term: String, for itemType: POSItemType) {
        DDLogInfo("POS: Saving search term '\(term)' for item type: \(itemType)")

        if searchHistory[itemType] == nil {
            searchHistory[itemType] = []
        }

        searchHistory[itemType]?.removeAll { $0 == term }

        searchHistory[itemType]?.insert(term, at: 0)

        if let count = searchHistory[itemType]?.count, count > maxHistorySize {
            searchHistory[itemType] = searchHistory[itemType]?.dropLast(count - maxHistorySize)
        }

        let allSearchTerms = searchHistory[itemType]?.joined(separator: ", ") ?? "[none]"
        DDLogInfo("POS: Saved search terms for item type: \(itemType) – \(allSearchTerms)")
    }

    /// Retrieves the search history for a specific item type
    /// - Parameter itemType: The type of item to get search history for
    /// - Returns: An array of search terms, ordered from most recent to oldest
    public func searchHistory(for itemType: POSItemType) -> [String] {
        return searchHistory[itemType] ?? []
    }

    /// Clears the search history for a specific item type
    /// - Parameter itemType: The type of item to clear search history for
    public func clearSearchHistory(for itemType: POSItemType) {
        searchHistory[itemType] = []
    }

    /// Clears all search history
    public func clearAllSearchHistory() {
        searchHistory.removeAll()
    }
}
