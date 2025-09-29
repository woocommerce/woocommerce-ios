import Foundation
import Yosemite

struct POSOrderListFetchAnalytics: POSOrderListFetchAnalyticsTracking {
    private let analytics: POSAnalyticsProviding

    init(analytics: POSAnalyticsProviding) {
        self.analytics = analytics
    }

    func trackOrdersFetchComplete(millisecondsSinceRequestSent: Int) {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListFetched(
            millisecondsSinceRequestSent: millisecondsSinceRequestSent
        ))
    }

    func trackOrdersSearchResultsFetchComplete(millisecondsSinceRequestSent: Int) {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListSearchResultsFetched(
            millisecondsSinceRequestSent: millisecondsSinceRequestSent
        ))
    }

    func trackOrdersNextPageLoaded(pageNumber: Int) {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListNextPageLoaded(
            pageNumber: pageNumber
        ))
    }
}
