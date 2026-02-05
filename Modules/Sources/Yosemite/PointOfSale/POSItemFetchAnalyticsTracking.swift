import Foundation

/// Protocol defining analytics tracking for Point of Sale items fetch functionality
public protocol POSItemFetchAnalyticsTracking {
    /// Tracks when a remote items fetch completes
    /// - Parameters:
    ///   - totalItems: The total number of items in the store
    func trackItemsFetchComplete(totalItems: Int)

    /// Tracks when a remote search results fetch completes
    /// - Parameters:
    ///   - millisecondsSinceRequestSent: The time taken to fetch results in milliseconds
    ///   - totalItems: The total number of items found in the search
    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int)

    /// Tracks when a local search results fetch completes
    /// - Parameters:
    ///   - millisecondsSinceRequestSent: The time taken to fetch results in milliseconds
    ///   - totalItems: The total number of items found in the search
    ///   - searchMethod: The search method used ("fts" or "like")
    ///   - source: The source of the results ("product" or "purchasable_items")
    func trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: Int,
                                              totalItems: Int,
                                              searchMethod: String,
                                              source: String)
}
