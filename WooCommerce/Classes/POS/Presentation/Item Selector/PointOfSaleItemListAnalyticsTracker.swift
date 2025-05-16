import Foundation
import WooFoundation
import enum Yosemite.POSItemType

struct PointOfSaleItemListAnalyticsTracker {
    private let itemType: POSItemType
    private let isSearching: Bool
    private let itemListType: ItemListType?

    init(itemType: POSItemType, isSearching: Bool) {
        self.itemType = itemType
        self.isSearching = isSearching
        self.itemListType = nil
    }

    init(itemListType: ItemListType) {
        self.itemType = itemListType.itemType
        self.isSearching = itemListType.isSearching
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
            event: WooAnalyticsEvent.PointOfSale.pointOfSaleItemsNextPageLoaded(itemType: itemType,
                                                                                searching: isSearching))
    }

    func trackRefresh() {
        ServiceLocator.analytics.track(
            event: WooAnalyticsEvent.PointOfSale.itemsPullToRefresh(
                 itemType: itemType,
                 searching: isSearching
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
