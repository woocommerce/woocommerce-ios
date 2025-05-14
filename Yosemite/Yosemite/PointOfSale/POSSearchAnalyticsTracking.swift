import Foundation

/// Protocol defining analytics tracking for Point of Sale search functionality
public protocol POSSearchAnalyticsTracking {
    /// Tracks when a remote search results fetch completes
    /// - Parameters:
    ///   - millisecondsSinceRequestSent: The time taken to fetch results in milliseconds
    ///   - totalItems: The total number of items found in the search
    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int)
}
