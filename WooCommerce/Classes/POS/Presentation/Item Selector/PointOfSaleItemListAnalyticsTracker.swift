import Foundation
import WooFoundation
import enum Yosemite.POSItemType

struct PointOfSaleItemListAnalyticsTracker {
    let source: WooAnalyticsEvent.PointOfSale.Source
    let sourceType: WooAnalyticsEvent.PointOfSale.SourceType

    init(
        source: WooAnalyticsEvent.PointOfSale.Source,
        sourceType: WooAnalyticsEvent.PointOfSale.SourceType
    ) {
        self.source = source
        self.sourceType = sourceType
    }

    init(selectedItemListType: ItemListType, searchTerm: String) {
        switch selectedItemListType {
        case .products(search: false):
            self.init(source: .product, sourceType: .list)
        case .coupons(search: false):
            self.init(source: .coupon, sourceType: .list)
        case .products(search: true):
            self.init(source: .product, sourceType: searchTerm.isEmpty ? .preSearch : .search)
        case .coupons(search: true):
            self.init(source: .coupon, sourceType: searchTerm.isEmpty ? .preSearch : .search)
        }
    }

    func trackItemListSelected(itemListType: ItemListType) {
        ServiceLocator.analytics.track(event: .PointOfSale.itemsHeaderTapped(itemListType: itemListType))
    }

    func trackNextPageWillLoad() {
        ServiceLocator.analytics.track(
            event: WooAnalyticsEvent.PointOfSale.itemsNextPageLoaded(
                source: source,
                sourceType: sourceType
            )
        )
    }

    func trackRefresh() {
        ServiceLocator.analytics.track(
            event: WooAnalyticsEvent.PointOfSale.itemsPullToRefresh(
                source: source,
                sourceType: sourceType
            )
        )
    }

    func trackSearchTapped(itemListType: ItemListType) {
        ServiceLocator.analytics.track(event: .PointOfSale.searchButtonTapped(itemListType: itemListType))
    }
}
