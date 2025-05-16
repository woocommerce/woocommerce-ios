import Foundation
import WooFoundation
import enum Yosemite.POSItemType

struct PointOfSaleItemListAnalyticsTracker {
    private let source: WooAnalyticsEvent.PointOfSale.Source
    private let sourceType: WooAnalyticsEvent.PointOfSale.SourceType
    private let itemListType: ItemListType?

    init(
        source: WooAnalyticsEvent.PointOfSale.Source,
        sourceType: WooAnalyticsEvent.PointOfSale.SourceType
    ) {
        self.source = source
        self.sourceType = sourceType
        self.itemListType = nil
    }

    init(
        itemListType: ItemListType,
        source: WooAnalyticsEvent.PointOfSale.Source,
        sourceType: WooAnalyticsEvent.PointOfSale.SourceType
    ) {
        self.source = source
        self.sourceType = sourceType
        self.itemListType = itemListType
    }

    func trackItemListSelected() {
        guard let itemListType else {
            return
        }
        switch itemListType {
        case .products:
            ServiceLocator.analytics.track(.pointOfSaleProductsTapped)
        case .coupons:
            ServiceLocator.analytics.track(.pointOfSaleCouponsTapped)
        }
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

    func trackSearchTapped() {
        guard let itemListType else {
            return
        }
        ServiceLocator.analytics.track(event: .PointOfSale.searchButtonTapped(itemListType: itemListType))
    }
}
