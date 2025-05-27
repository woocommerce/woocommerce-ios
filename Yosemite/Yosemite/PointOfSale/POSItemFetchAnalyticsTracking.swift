import Foundation

/// Protocol defining analytics tracking for Point of Sale items fetch functionality
public protocol POSItemFetchAnalyticsTracking {
    /// Tracks when a remote items fetch completes
    /// - Parameters:
    ///   - totalItems: The total number of items in the store
    func trackItemsFetchComplete(totalItems: Int)
}
