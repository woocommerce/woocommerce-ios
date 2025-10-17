import Foundation
import enum Yosemite.POSItemType
import struct WooFoundation.WooAnalyticsEvent

struct PointOfSaleItemListAnalyticsTracker {
    private let sourceView: WooAnalyticsEvent.PointOfSale.SourceView
    private let sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType
    private let analytics: POSAnalyticsProviding

    init(
        sourceView: WooAnalyticsEvent.PointOfSale.SourceView,
        sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType,
        analytics: POSAnalyticsProviding
    ) {
        self.sourceView = sourceView
        self.sourceViewType = sourceViewType
        self.analytics = analytics
    }

    init(
        selectedItemListType: ItemListType,
        searchTerm: String,
        analytics: POSAnalyticsProviding
    ) {
        switch selectedItemListType {
        case .products(search: false):
            self.init(sourceView: .product, sourceViewType: .list, analytics: analytics)
        case .coupons(search: false):
            self.init(sourceView: .coupon, sourceViewType: .list, analytics: analytics)
        case .products(search: true):
            self.init(sourceView: .product, sourceViewType: searchTerm.isEmpty ? .preSearch : .search, analytics: analytics)
        case .coupons(search: true):
            self.init(sourceView: .coupon, sourceViewType: searchTerm.isEmpty ? .preSearch : .search, analytics: analytics)
        }
    }

    func trackItemListSelected(itemListType: ItemListType) {
        analytics.track(event: .PointOfSale.itemsHeaderTapped(itemListType: itemListType))
    }

    func trackNextPageWillLoad() {
        analytics.track(
            event: WooAnalyticsEvent.PointOfSale.itemsNextPageLoaded(
                sourceView: sourceView,
                sourceViewType: sourceViewType
            )
        )
    }

    func trackRefresh() {
        analytics.track(
            event: WooAnalyticsEvent.PointOfSale.itemsPullToRefresh(
                sourceView: sourceView,
                sourceViewType: sourceViewType
            )
        )
    }

    func trackSearchTapped(itemListType: ItemListType) {
        analytics.track(event: .PointOfSale.searchButtonTapped(itemListType: itemListType))
    }
}
