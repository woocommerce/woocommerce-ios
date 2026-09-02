import Foundation

/// The search method that produced the results. Present on both the local and the remote search
/// events so a single query can span the local catalog rollout without a fabricated step change.
///
/// `remote` declines as stores adopt the local catalog, but never reaches zero: coupon search has no
/// local catalog at all (`PointOfSaleCouponFetchStrategy`), so every coupon search reports `remote`.
public enum POSSearchMethod: String {
    case fts
    case remote
}

/// The source of search results
public enum POSSearchSource: String {
    case purchasableItems = "purchasable_items"
}

/// Protocol defining analytics tracking for Point of Sale items fetch functionality
public protocol POSItemFetchAnalyticsTracking {
    /// Tracks when a remote items fetch completes
    /// - Parameters:
    ///   - totalItems: The total number of items in the store
    func trackItemsFetchComplete(totalItems: Int)

    /// Tracks when a remote search results fetch completes. Always reports `POSSearchMethod.remote`.
    /// - Parameters:
    ///   - millisecondsSinceRequestSent: The time taken to fetch results in milliseconds
    ///   - totalItems: The total number of items found in the search
    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int)

    /// Tracks when a local search results fetch completes
    /// - Parameters:
    ///   - millisecondsSinceRequestSent: The time taken to fetch results in milliseconds
    ///   - totalItems: The total number of items found in the search
    ///   - searchMethod: How the local catalog produced the results
    ///   - source: The source of the results
    func trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: Int,
                                              totalItems: Int,
                                              searchMethod: POSSearchMethod,
                                              source: POSSearchSource)
}
