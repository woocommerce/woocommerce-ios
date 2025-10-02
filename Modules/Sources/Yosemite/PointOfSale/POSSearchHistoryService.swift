import Foundation
import Storage

public protocol POSSearchHistoryProviding {
    func saveSuccessfulSearch(term: String, for itemType: POSItemType)
    func searchHistory(for itemType: POSItemType) -> [String]
}

/// Service for managing search history in the Point of Sale
public final class POSSearchHistoryService: POSSearchHistoryProviding {
    private let maxHistorySize: Int
    private let siteID: Int64
    private let siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol

    /// Initializes a new search history service
    /// - Parameters:
    ///   - maxHistorySize: Maximum number of search terms to keep in history per item type
    ///   - siteID: The site ID to store search history for
    ///   - siteSpecificAppSettingsStoreMethods: The store methods to use for persistent storage
    public init(maxHistorySize: Int = 10,
                siteID: Int64,
                siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol? = nil) {
        self.maxHistorySize = maxHistorySize
        self.siteID = siteID
        self.siteSpecificAppSettingsStoreMethods = siteSpecificAppSettingsStoreMethods ?? SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage())
    }

    /// Saves a successful search term to the history
    /// - Parameters:
    ///   - term: The search term to save
    ///   - itemType: The type of item being searched
    public func saveSuccessfulSearch(term: String, for itemType: POSItemType) {
        DDLogInfo("POS: Saving search term '\(term)' for item type: \(itemType)")

        var searchTerms = siteSpecificAppSettingsStoreMethods.getSearchTerms(for: itemType, siteID: siteID)

        // Remove the term if it already exists
        searchTerms.removeAll { $0 == term }

        // Add the term at the beginning
        searchTerms.insert(term, at: 0)

        // Trim to max size if needed
        if searchTerms.count > maxHistorySize {
            searchTerms = Array(searchTerms.dropLast(searchTerms.count - maxHistorySize))
        }

        // Save the updated terms
        siteSpecificAppSettingsStoreMethods.setSearchTerms(searchTerms, for: itemType, siteID: siteID)

        let allSearchTerms = searchTerms.joined(separator: ", ")
        DDLogInfo("POS: Saved search terms for item type: \(itemType) – \(allSearchTerms)")
    }

    /// Retrieves the search history for a specific item type
    /// - Parameter itemType: The type of item to get search history for
    /// - Returns: An array of search terms, ordered from most recent to oldest
    public func searchHistory(for itemType: POSItemType) -> [String] {
        return siteSpecificAppSettingsStoreMethods.getSearchTerms(for: itemType, siteID: siteID)
    }
}
