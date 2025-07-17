import Testing
import Foundation
import enum Yosemite.POSItem
import enum Yosemite.POSItemType
import protocol Yosemite.POSSearchHistoryProviding
@testable import WooCommerce

struct POSItemActionHandlerTests {
    @available(iOS 17.0, *)
    @Test func handleTap_when_attempt_to_add_duplicated_coupons_in_list_then_does_not_add_it_to_cart() async throws {
        let aggregateModel = PointOfSaleAggregateModel(entryPointController: POSEntryPointController(eligibilityChecker: MockPOSEligibilityChecker()),
                                                       itemsController: MockPointOfSaleItemsController(),
                                                       purchasableItemsSearchController: MockPointOfSalePurchasableItemsSearchController(),
                                                       couponsController: MockPointOfSaleCouponsController(),
                                                       couponsSearchController: MockPointOfSaleCouponsController(),
                                                       cardPresentPaymentService: MockCardPresentPaymentService(),
                                                       orderController: MockPointOfSaleOrderController(),
                                                       collectOrderPaymentAnalyticsTracker: MockPOSCollectOrderPaymentAnalyticsTracker(),
                                                       searchHistoryService: MockPOSSearchHistoryService(),
                                                       popularPurchasableItemsController: MockPointOfSaleItemsController(),
                                                       barcodeScanService: MockPointOfSaleBarcodeScanService())
        let sut = StandardPOSItemActionHandler(
            posModel: aggregateModel,
            sourceView: .coupon,
            sourceViewType: .list
        )

        let coupon = makeCouponItem(code: "DISCOUNT!")

        sut.handleTap(coupon)
        sut.handleTap(coupon)
        sut.handleTap(coupon)

        #expect(aggregateModel.cart.coupons.count == 1)
    }

    @available(iOS 17.0, *)
    @Test func handleTap_when_attempt_to_add_duplicated_coupons_in_search_then_does_not_add_it_to_cart() async throws {
        let aggregateModel = PointOfSaleAggregateModel(entryPointController: POSEntryPointController(eligibilityChecker: MockPOSEligibilityChecker()),
                                                       itemsController: MockPointOfSaleItemsController(),
                                                       purchasableItemsSearchController: MockPointOfSalePurchasableItemsSearchController(),
                                                       couponsController: MockPointOfSaleCouponsController(),
                                                       couponsSearchController: MockPointOfSaleCouponsController(),
                                                       cardPresentPaymentService: MockCardPresentPaymentService(),
                                                       orderController: MockPointOfSaleOrderController(),
                                                       collectOrderPaymentAnalyticsTracker: MockPOSCollectOrderPaymentAnalyticsTracker(),
                                                       searchHistoryService: MockPOSSearchHistoryService(),
                                                       popularPurchasableItemsController: MockPointOfSaleItemsController(),
                                                       barcodeScanService: MockPointOfSaleBarcodeScanService())
        let sut = SearchResultItemActionHandler(
            posModel: aggregateModel,
            searchTerm: "",
            itemType: .coupon,
            sourceView: .coupon
        )

        let coupon = makeCouponItem(code: "DISCOUNT!")

        sut.handleTap(coupon)
        sut.handleTap(coupon)
        sut.handleTap(coupon)

        #expect(aggregateModel.cart.coupons.count == 1)
    }

    @available(iOS 17.0, *)
    @Test func handleTap_when_attempt_to_add_duplicated_products_in_list_then_adds_them_to_cart() async throws {
        let aggregateModel = PointOfSaleAggregateModel(entryPointController: POSEntryPointController(eligibilityChecker: MockPOSEligibilityChecker()),
                                                       itemsController: MockPointOfSaleItemsController(),
                                                       purchasableItemsSearchController: MockPointOfSalePurchasableItemsSearchController(),
                                                       couponsController: MockPointOfSaleCouponsController(),
                                                       couponsSearchController: MockPointOfSaleCouponsController(),
                                                       cardPresentPaymentService: MockCardPresentPaymentService(),
                                                       orderController: MockPointOfSaleOrderController(),
                                                       collectOrderPaymentAnalyticsTracker: MockPOSCollectOrderPaymentAnalyticsTracker(),
                                                       searchHistoryService: MockPOSSearchHistoryService(),
                                                       popularPurchasableItemsController: MockPointOfSaleItemsController(),
                                                       barcodeScanService: MockPointOfSaleBarcodeScanService())
        let sut = StandardPOSItemActionHandler(
            posModel: aggregateModel,
            sourceView: .product,
            sourceViewType: .list
        )

        let product = makeProductItem()

        sut.handleTap(product)
        sut.handleTap(product)
        sut.handleTap(product)

        #expect(aggregateModel.cart.purchasableItems.count == 3)
    }

    @available(iOS 17.0, *)
    @Test func handleTap_when_attempt_to_add_duplicated_products_in_search_then_adds_them_to_cart() async throws {
        let aggregateModel = PointOfSaleAggregateModel(entryPointController: POSEntryPointController(eligibilityChecker: MockPOSEligibilityChecker()),
                                                       itemsController: MockPointOfSaleItemsController(),
                                                       purchasableItemsSearchController: MockPointOfSalePurchasableItemsSearchController(),
                                                       couponsController: MockPointOfSaleCouponsController(),
                                                       couponsSearchController: MockPointOfSaleCouponsController(),
                                                       cardPresentPaymentService: MockCardPresentPaymentService(),
                                                       orderController: MockPointOfSaleOrderController(),
                                                       collectOrderPaymentAnalyticsTracker: MockPOSCollectOrderPaymentAnalyticsTracker(),
                                                       searchHistoryService: MockPOSSearchHistoryService(),
                                                       popularPurchasableItemsController: MockPointOfSaleItemsController(),
                                                       barcodeScanService: MockPointOfSaleBarcodeScanService())
        let sut = SearchResultItemActionHandler(
            posModel: aggregateModel,
            searchTerm: "",
            itemType: .product,
            sourceView: .product
        )

        let product = makeProductItem()

        sut.handleTap(product)
        sut.handleTap(product)
        sut.handleTap(product)

        #expect(aggregateModel.cart.purchasableItems.count == 3)
    }
}

private func makeCouponItem(code: String = "") -> POSItem {
    return .coupon(.init(id: UUID(), code: code))
}

private func makeProductItem() -> POSItem {
    return .simpleProduct(.init(id: UUID(),
                                name: "some product name",
                                formattedPrice: "$10.00",
                                productID: 123,
                                price: "10",
                                manageStock: false,
                                stockQuantity: nil,
                                stockStatusKey: ""))
}
