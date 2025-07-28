import Foundation
import WooFoundation
import enum Yosemite.POSItemType
import protocol Yosemite.POSItemFetchAnalyticsTracking

/// Analytics tracking for Point of Sale item fetch functionality
struct POSItemFetchAnalytics: POSItemFetchAnalyticsTracking {
    /// The type of item being fetched
    private let itemType: POSItemType
    /// The analytics service to use for tracking
    private let analytics: Analytics

    /// Creates a new analytics tracker for the given item type
    /// - Parameters:
    ///   - itemType: The type of item being fetched (e.g. "product", "variation")
    ///   - analytics: The analytics service to use for tracking. Defaults to ServiceLocator.analytics
    init(itemType: POSItemType, analytics: Analytics = ServiceLocator.analytics) {
        self.itemType = itemType
        self.analytics = analytics
    }

    /// Tracks when a remote fetch completes
    /// - Parameters:
    ///   - totalItems: The total number of items found in the search
    func trackItemsFetchComplete(totalItems: Int) {
        analytics.track(
            event: .PointOfSale.pointOfSaleItemsFetched(
                itemType: itemType,
                totalItems: totalItems
            )
        )
    }

    /// Tracks when a remote search results fetch completes
    /// - Parameters:
    ///   - milliseconds: The time taken to fetch results in milliseconds
    ///   - totalItems: The total number of items found in the search
    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int) {
        analytics.track(
            event: .PointOfSale.pointOfSaleSearchRemoteResultsFetched(
                itemType: itemType,
                resultsCount: totalItems,
                millisecondsSinceRequestSent: millisecondsSinceRequestSent
            )
        )
    }
}
