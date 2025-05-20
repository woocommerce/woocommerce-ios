import Foundation
import WooFoundation
import enum Yosemite.POSItemType

struct PointOfSaleItemListAnalyticsTracker {
    private let source: WooAnalyticsEvent.PointOfSale.Source
    private let sourceType: WooAnalyticsEvent.PointOfSale.SourceType
    private let analytics: Analytics

    init(
        source: WooAnalyticsEvent.PointOfSale.Source,
        sourceType: WooAnalyticsEvent.PointOfSale.SourceType,
        analytics: Analytics = ServiceLocator.analytics
    ) {
        self.source = source
        self.sourceType = sourceType
        self.analytics = analytics
    }

    init(
        selectedItemListType: ItemListType,
        searchTerm: String,
        analytics: Analytics = ServiceLocator.analytics
    ) {
        switch selectedItemListType {
        case .products(search: false):
            self.init(source: .product, sourceType: .list, analytics: analytics)
        case .coupons(search: false):
            self.init(source: .coupon, sourceType: .list, analytics: analytics)
        case .products(search: true):
            self.init(source: .product, sourceType: searchTerm.isEmpty ? .preSearch : .search, analytics: analytics)
        case .coupons(search: true):
            self.init(source: .coupon, sourceType: searchTerm.isEmpty ? .preSearch : .search, analytics: analytics)
        }
    }

    func trackItemListSelected(itemListType: ItemListType) {
        analytics.track(event: .PointOfSale.itemsHeaderTapped(itemListType: itemListType))
    }

    func trackNextPageWillLoad() {
        analytics.track(
            event: WooAnalyticsEvent.PointOfSale.itemsNextPageLoaded(
                source: source,
                sourceType: sourceType
            )
        )
    }

    func trackRefresh() {
        analytics.track(
            event: WooAnalyticsEvent.PointOfSale.itemsPullToRefresh(
                source: source,
                sourceType: sourceType
            )
        )
    }

    func trackSearchTapped(itemListType: ItemListType) {
        analytics.track(event: .PointOfSale.searchButtonTapped(itemListType: itemListType))
    }
}
