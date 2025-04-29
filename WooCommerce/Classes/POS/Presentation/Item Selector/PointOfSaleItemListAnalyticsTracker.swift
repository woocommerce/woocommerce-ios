import Foundation
import WooFoundation
import enum Yosemite.POSItemType

struct PointOfSaleItemListAnalyticsTracker {
    private let itemType: POSItemType
    private let isSearching: Bool

    init(itemType: POSItemType, isSearching: Bool) {
        self.itemType = itemType
        self.isSearching = isSearching
    }

    init(itemListType: ItemListType) {
        self.itemType = itemListType.itemType
        self.isSearching = itemListType.isSearching
    }

    func trackNextPageWillLoad() {
        ServiceLocator.analytics.track(
            event: WooAnalyticsEvent.PointOfSale.pointOfSaleItemsNextPageLoaded(itemType: itemType,
                                                                                searching: isSearching))
    }

    func trackRefresh() {
        ServiceLocator.analytics.track(refreshEvent)
    }

    private var refreshEvent: WooAnalyticsStat {
        switch itemType {
        case .product:
                .pointOfSaleProductsPullToRefresh
        case .coupon:
                .pointOfSaleCouponsPullToRefresh
        case .variation:
                .pointOfSaleVariationsPullToRefresh
        }
    }
}
