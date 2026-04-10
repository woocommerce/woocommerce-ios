import Foundation

/// Protocol defining analytics tracking for Point of Sale orders fetch functionality
public protocol POSOrderListFetchAnalyticsTracking {
    /// Tracks when a remote orders fetch completes
    /// - Parameters:
    ///   - millisecondsSinceRequestSent: The time taken to fetch results in milliseconds
    func trackOrdersFetchComplete(millisecondsSinceRequestSent: Int)

    /// Tracks when a remote search results fetch completes for orders
    /// - Parameters:
    ///   - millisecondsSinceRequestSent: The time taken to fetch results in milliseconds
    func trackOrdersSearchResultsFetchComplete(millisecondsSinceRequestSent: Int)

    /// Tracks when next page of orders is loaded
    /// - Parameters:
    ///   - pageNumber: The page number that was loaded
    func trackOrdersNextPageLoaded(pageNumber: Int)
}
