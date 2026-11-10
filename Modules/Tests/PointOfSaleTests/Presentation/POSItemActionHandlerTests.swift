import Testing
import Foundation
import enum Yosemite.POSItem
import enum Yosemite.POSItemType
import struct Yosemite.POSItemIdentifier
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol
import protocol Yosemite.POSSearchHistoryProviding
@testable import PointOfSale

@MainActor
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

        sut.handleTap(product, position: 0)
        sut.handleTap(product, position: 0)
        sut.handleTap(product, position: 0)

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

    @Test func handleTapOnAppliedCoupon_when_coupon_is_in_cart_then_removes_it_and_tracks_removal() async throws {
        // Given
        let aggregateModel = makePointOfSaleAggregateModel()
        let analytics = MockPOSAnalytics()
        let sut = StandardPOSItemActionHandler(
            posModel: aggregateModel,
            sourceView: .coupon,
            sourceViewType: .list,
            analytics: analytics
        )
        let coupon = makeCouponItem(code: "DISCOUNT!")
        let otherCoupon = makeCouponItem(code: "OTHER", itemID: 2)
        sut.handleTap(coupon, position: 0)
        sut.handleTap(otherCoupon, position: 1)
        analytics.events.removeAll()

        // When
        sut.handleTapOnAppliedCoupon(coupon)

        // Then
        #expect(aggregateModel.cart.coupons.map(\.code) == ["OTHER"])
        let event = try #require(analytics.events.first)
        #expect(analytics.events.count == 1)
        #expect(event.eventName == "item_removed_from_cart")
        #expect(event.properties["source"] as? String == "coupon")
        #expect(event.properties["item_type"] as? String == "coupon")
    }

    @Test func handleTapOnAppliedCoupon_when_search_result_coupon_is_in_cart_then_removes_it_and_tracks_removal() async throws {
        // Given
        let aggregateModel = makePointOfSaleAggregateModel()
        let analytics = MockPOSAnalytics()
        let sut = SearchResultItemActionHandler(
            posModel: aggregateModel,
            searchTerm: "DIS",
            itemType: .coupon,
            sourceView: .coupon,
            analytics: analytics
        )
        let coupon = makeCouponItem(code: "DISCOUNT!")
        sut.handleTap(coupon, position: 0)
        analytics.events.removeAll()

        // When
        sut.handleTapOnAppliedCoupon(coupon)

        // Then
        #expect(aggregateModel.cart.coupons.isEmpty)
        #expect(analytics.events.map(\.eventName) == ["item_removed_from_cart"])
    }

    @Test func handleTapOnAppliedCoupon_when_coupon_is_not_in_cart_then_does_nothing() async throws {
        // Given
        let aggregateModel = makePointOfSaleAggregateModel()
        let analytics = MockPOSAnalytics()
        let sut = StandardPOSItemActionHandler(
            posModel: aggregateModel,
            sourceView: .coupon,
            sourceViewType: .list,
            analytics: analytics
        )

        // When
        sut.handleTapOnAppliedCoupon(makeCouponItem(code: "DISCOUNT!"))

        // Then
        #expect(aggregateModel.cart.coupons.isEmpty)
        #expect(analytics.events.isEmpty)
    }
}

private func makeCouponItem(code: String = "", itemID: Int64 = 1) -> POSItem {
    return .coupon(.init(id: POSItemIdentifier(underlyingType: .product, itemID: itemID), code: code))
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

@MainActor
private func makePointOfSaleAggregateModel(
    entryPointController: POSEntryPointController? = nil,
    itemsController: PointOfSaleItemsControllerProtocol? = nil,
    purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol? = nil,
    couponsController: PointOfSaleCouponsControllerProtocol? = nil,
    couponsSearchController: PointOfSaleSearchingItemsControllerProtocol? = nil,
    cardPresentPaymentService: CardPresentPaymentFacade? = nil,
    orderController: PointOfSaleOrderControllerProtocol? = nil,
    settingsController: POSSettingsControllerProtocol? = nil,
    analytics: POSAnalyticsProviding = MockPOSAnalytics(),
    collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = MockPOSCollectOrderPaymentAnalyticsTracker(),
    searchHistoryService: POSSearchHistoryProviding = MockPOSSearchHistoryService(),
    popularPurchasableItemsController: PointOfSaleItemsControllerProtocol? = nil,
    barcodeScanService: PointOfSaleBarcodeScanServiceProtocol? = nil
) -> PointOfSaleAggregateModel {
    let cardPresentPaymentService = cardPresentPaymentService ?? MockCardPresentPaymentService()

    return PointOfSaleAggregateModel(
        entryPointController: entryPointController ?? POSEntryPointController(eligibilityChecker: MockPOSEligibilityChecker()),
        itemsController: itemsController ?? MockPointOfSaleItemsController(),
        purchasableItemsSearchController: purchasableItemsSearchController ?? MockPointOfSalePurchasableItemsSearchController(),
        couponsController: couponsController ?? MockPointOfSaleCouponsController(),
        couponsSearchController: couponsSearchController ?? MockPointOfSaleCouponsController(),
        cardPresentPaymentService: cardPresentPaymentService,
        orderController: orderController ?? MockPointOfSaleOrderController(),
        settingsController: settingsController ?? MockPOSSettingsController(),
        analytics: analytics,
        collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
        searchHistoryService: searchHistoryService,
        popularPurchasableItemsController: popularPurchasableItemsController ?? MockPointOfSaleItemsController(),
        barcodeScanService: barcodeScanService ?? MockPointOfSaleBarcodeScanService(),
        receiptSender: MockPOSReceiptSender(),
        siteID: 0
    )
}
