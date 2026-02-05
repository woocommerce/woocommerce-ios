import Testing
import Foundation
import enum Yosemite.POSItem
import enum Yosemite.POSItemType
import struct Yosemite.POSItemIdentifier
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol
import protocol Yosemite.POSSearchHistoryProviding
@testable import PointOfSale

struct POSItemActionHandlerTests {
    @Test func handleTap_when_attempt_to_add_duplicated_coupons_in_list_then_does_not_add_it_to_cart() async throws {
        let aggregateModel = makePointOfSaleAggregateModel()
        let sut = StandardPOSItemActionHandler(
            posModel: aggregateModel,
            sourceView: .coupon,
            sourceViewType: .list,
            analytics: MockPOSAnalytics()
        )

        let coupon = makeCouponItem(code: "DISCOUNT!")

        sut.handleTap(coupon, position: 0)
        sut.handleTap(coupon, position: 0)
        sut.handleTap(coupon, position: 0)

        #expect(aggregateModel.cart.coupons.count == 1)
    }

    @Test func handleTap_when_attempt_to_add_duplicated_coupons_in_search_then_does_not_add_it_to_cart() async throws {
        let aggregateModel = makePointOfSaleAggregateModel()
        let sut = SearchResultItemActionHandler(
            posModel: aggregateModel,
            searchTerm: "",
            itemType: .coupon,
            sourceView: .coupon,
            analytics: MockPOSAnalytics()
        )

        let coupon = makeCouponItem(code: "DISCOUNT!")

        sut.handleTap(coupon, position: 0)
        sut.handleTap(coupon, position: 0)
        sut.handleTap(coupon, position: 0)

        #expect(aggregateModel.cart.coupons.count == 1)
    }

    @Test func handleTap_when_attempt_to_add_duplicated_products_in_list_then_adds_them_to_cart() async throws {
        let aggregateModel = makePointOfSaleAggregateModel()
        let sut = StandardPOSItemActionHandler(
            posModel: aggregateModel,
            sourceView: .product,
            sourceViewType: .list,
            analytics: MockPOSAnalytics()
        )

        let product = makeProductItem()

        sut.handleTap(product, position: nil)
        sut.handleTap(product, position: nil)
        sut.handleTap(product, position: nil)

        #expect(aggregateModel.cart.purchasableItems.count == 3)
    }

    @Test func handleTap_when_attempt_to_add_duplicated_products_in_search_then_adds_them_to_cart() async throws {
        let aggregateModel = makePointOfSaleAggregateModel()
        let sut = SearchResultItemActionHandler(
            posModel: aggregateModel,
            searchTerm: "",
            itemType: .product,
            sourceView: .product,
            analytics: MockPOSAnalytics()
        )

        let product = makeProductItem()

        sut.handleTap(product, position: 0)
        sut.handleTap(product, position: 1)
        sut.handleTap(product, position: 2)

        #expect(aggregateModel.cart.purchasableItems.count == 3)
    }
}

private func makeCouponItem(code: String = "") -> POSItem {
    return .coupon(.init(id: POSItemIdentifier(underlyingType: .product, itemID: 1), code: code))
}

private func makeProductItem() -> POSItem {
    return .simpleProduct(.init(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                                name: "some product name",
                                formattedPrice: "$10.00",
                                productID: 123,
                                price: "10",
                                manageStock: false,
                                stockQuantity: nil,
                                stockStatusKey: ""))
}

private func makePointOfSaleAggregateModel(
    entryPointController: POSEntryPointController = POSEntryPointController(eligibilityChecker: MockPOSEligibilityChecker()),
    itemsController: PointOfSaleItemsControllerProtocol = MockPointOfSaleItemsController(),
    purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol = MockPointOfSalePurchasableItemsSearchController(),
    couponsController: PointOfSaleCouponsControllerProtocol = MockPointOfSaleCouponsController(),
    couponsSearchController: PointOfSaleSearchingItemsControllerProtocol = MockPointOfSaleCouponsController(),
    cardPresentPaymentService: CardPresentPaymentFacade = MockCardPresentPaymentService(),
    orderController: PointOfSaleOrderControllerProtocol = MockPointOfSaleOrderController(),
    settingsController: POSSettingsControllerProtocol = MockPOSSettingsController(),
    analytics: POSAnalyticsProviding = MockPOSAnalytics(),
    collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = MockPOSCollectOrderPaymentAnalyticsTracker(),
    searchHistoryService: POSSearchHistoryProviding = MockPOSSearchHistoryService(),
    popularPurchasableItemsController: PointOfSaleItemsControllerProtocol = MockPointOfSaleItemsController(),
    barcodeScanService: PointOfSaleBarcodeScanServiceProtocol = MockPointOfSaleBarcodeScanService()
) -> PointOfSaleAggregateModel {
    PointOfSaleAggregateModel(
        entryPointController: entryPointController,
        itemsController: itemsController,
        purchasableItemsSearchController: purchasableItemsSearchController,
        couponsController: couponsController,
        couponsSearchController: couponsSearchController,
        cardPresentPaymentService: cardPresentPaymentService,
        orderController: orderController,
        settingsController: settingsController,
        analytics: analytics,
        collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
        searchHistoryService: searchHistoryService,
        popularPurchasableItemsController: popularPurchasableItemsController,
        barcodeScanService: barcodeScanService,
        siteID: 0
    )
}
