import Foundation
import Yosemite
import struct WooFoundation.WooAnalyticsEvent

public struct POSOrderListFetchAnalytics: POSOrderListFetchAnalyticsTracking {
    private let analytics: POSAnalyticsProviding

    public init(analytics: POSAnalyticsProviding) {
        self.analytics = analytics
    }

    public func trackOrdersFetchComplete(millisecondsSinceRequestSent: Int) {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListFetched(
            millisecondsSinceRequestSent: millisecondsSinceRequestSent
        ))
    }

    public func trackOrdersSearchResultsFetchComplete(millisecondsSinceRequestSent: Int) {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListSearchResultsFetched(
            millisecondsSinceRequestSent: millisecondsSinceRequestSent
        ))
    }

    public func trackOrdersNextPageLoaded(pageNumber: Int) {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListNextPageLoaded(
            pageNumber: pageNumber
        ))
    }
}
