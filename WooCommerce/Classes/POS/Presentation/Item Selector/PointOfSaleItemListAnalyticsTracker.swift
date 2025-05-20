import Foundation
import WooFoundation
import enum Yosemite.POSItemType

struct PointOfSaleItemListAnalyticsTracker {
    private let source: WooAnalyticsEvent.PointOfSale.Source
    private let sourceType: WooAnalyticsEvent.PointOfSale.SourceType

    init(
        source: WooAnalyticsEvent.PointOfSale.Source,
        sourceType: WooAnalyticsEvent.PointOfSale.SourceType
    ) {
        self.source = source
        self.sourceType = sourceType
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
