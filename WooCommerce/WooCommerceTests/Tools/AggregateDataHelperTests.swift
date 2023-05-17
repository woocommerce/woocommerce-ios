import XCTest
import Foundation
@testable import WooCommerce
@testable import Networking
@testable import WooFoundation


/// AggregateOrderItem Tests
///
final class AggregateDataHelperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 9876543210

    /// Order ID.
    ///
    private let orderID: Int64 = 560

    /// Verifies all refunds are loaded
    ///
    func testRefundsCount() {
        let refunds = mapLoadAllRefundsResponse()
        let expected = 4
        let actual = refunds.count

        XCTAssertEqual(expected, actual)
    }

    /// Verifies refunded products are calculated correctly.
    ///
    func testRefundedProductsCount() {
        let refunds = mapLoadAllRefundsResponse()
        let expected = Decimal(8)
        let actual = AggregateDataHelper.refundedProductsCount(from: refunds)

        XCTAssertEqual(expected, actual)
    }

    /// Verifies refunded products are combined and sorted correctly.
    ///
    func testRefundedProductsSortedSuccessfully() {
        let productID: Int64 = 1
        // The itemID (63 in this case) is relevant to retrieve the attributes. A refund order item has in its properties the refunded item id, to be used
        // to query the attibutes from the order items.
        let orderItems = [MockOrderItem.sampleItem(itemID: 63, productID: productID, quantity: 3, attributes: testOrderItemAttributes)]
        let refunds = mapLoadAllRefundsResponse()
        let expectedProducts = expectedRefundedProducts()

        guard let actualProducts = AggregateDataHelper.combineRefundedProducts(from: refunds, orderItems: orderItems) else {
            XCTFail("Error: failed to combine products.")
            return
        }

        let count = actualProducts.count
        for index in 0..<count {
            let actual = actualProducts[index]
            let expected = expectedProducts[index]
            XCTAssertEqual(expected.productID, actual.productID)
            XCTAssertEqual(expected.variationID, actual.variationID)
            XCTAssertEqual(expected.name, actual.name)
            XCTAssertEqual(expected.quantity, actual.quantity)
            XCTAssertEqual(expected.total, actual.total)
            XCTAssertEqual(expected.sku, actual.sku)
            XCTAssertEqual(expected.attributes, actual.attributes)
        }
    }

    /// Verifies that aggregate order items filter out objects with zero quantities.
    ///
    func testAggregateOrderItemsFilterOutZeroQuantities() {
        let orders = mapLoadAllOrdersResponse()

        guard let order = orders.first(where: { $0.orderID == orderID }) else {
            XCTFail("Error: could not find order with the specified orderID.")
            return
        }

        let refunds = mapLoadAllRefundsResponse()
        let expectedCount = 7
        let actual = AggregateDataHelper.combineOrderItems(order.items, with: refunds)

        XCTAssertEqual(expectedCount, actual.count)
    }

    func test_AggregateOrderItem_has_attributes_from_OrderItem() {
        // Given
        let productID: Int64 = 1
        let orderItems = [MockOrderItem.sampleItem(itemID: 62, productID: productID, quantity: 3, attributes: testOrderItemAttributes)]
        let order = MockOrders().empty().copy(items: orderItems)
        let refundItems = [MockRefunds.sampleRefundItem(productID: productID)]
        let refunds = [MockRefunds.sampleRefund(items: refundItems)]

        // When
        let aggregatedOrderItems = AggregateDataHelper.combineOrderItems(order.items, with: refunds)

        // Then
        XCTAssertEqual(aggregatedOrderItems.count, 1)
        XCTAssertEqual(aggregatedOrderItems[0].attributes, testOrderItemAttributes)
    }

    func test_two_order_items_with_same_productID_and_different_itemIDs_create_two_AggregateOrderItems() {
        // Given
        let productID: Int64 = 1
        let orderItems = [MockOrderItem.sampleItem(itemID: 62, productID: productID, quantity: 1),
                          MockOrderItem.sampleItem(itemID: 63, productID: productID, quantity: 1)]
        let order = MockOrders().empty().copy(items: orderItems)
        let refundItems = [MockRefunds.sampleRefundItem(productID: productID, refundedItemID: "62")]
        let refunds = [MockRefunds.sampleRefund(items: refundItems)]

        // When
        let aggregatedOrderItems = AggregateDataHelper.combineOrderItems(order.items, with: refunds)

        // Then
        XCTAssertEqual(aggregatedOrderItems.count, 2)
    }

    func test_two_refunds_with_same_productID_and_different_itemIDs_create_two_AggregateOrderItems() {
        // Given
        let productID: Int64 = 1
        let orderItems = [MockOrderItem.sampleItem(itemID: 62, productID: productID, quantity: 3)]
        let refundItems = [MockRefunds.sampleRefundItem(productID: productID, refundedItemID: "62", quantity: 1),
                           MockRefunds.sampleRefundItem(productID: productID, refundedItemID: "63", quantity: 1)]
        let refunds = [MockRefunds.sampleRefund(items: refundItems)]

        // When
        let aggregatedRefunds = AggregateDataHelper.combineRefundedProducts(from: refunds, orderItems: orderItems)

        // Then
        XCTAssertEqual(aggregatedRefunds?.count, 2)
    }
}


private extension AggregateDataHelperTests {
    /// Used when testing that the item attributes are properly retrieved, for order items and refunds
    var testOrderItemAttributes: [OrderItemAttribute] {
        [OrderItemAttribute(metaID: 170, name: "Packaging", value: "Yes")]
    }

    /// Returns the OrderListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrders(from filename: String) -> [Order] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! OrderListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the RefundListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapRefunds(from filename: String) -> [Refund] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! RefundListMapper(siteID: dummySiteID, orderID: orderID).map(response: response)
    }

    /// Returns the OrderListMapper output upon receiving `orders-load-all`
    ///
    func mapLoadAllOrdersResponse() -> [Order] {
        return mapOrders(from: "orders-load-all")
    }

    /// Returns the RefundListMapper output upon receiving `order-560-all-refunds`
    ///
    func mapLoadAllRefundsResponse() -> [Refund] {
        return mapRefunds(from: "order-560-all-refunds")
    }

    /// Returns the sorted, expected array of refunded products
    ///
    func expectedRefundedProducts() -> [AggregateOrderItem] {
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        let item0 = AggregateOrderItem(
            itemID: "59",
            productID: 24,
            variationID: 0,
            name: "Happy Ninja",
            price: currencyFormatter.convertToDecimal("31.5") ?? NSDecimalNumber.zero,
            quantity: -1,
            sku: "HOODIE-HAPPY-NINJA",
            total: currencyFormatter.convertToDecimal("-31.50") ?? NSDecimalNumber.zero,
            attributes: []
        )

        let item1 = AggregateOrderItem(
            itemID: "60",
            productID: 22,
            variationID: 0,
            name: "Ninja Silhouette",
            price: currencyFormatter.convertToDecimal("18") ?? NSDecimalNumber.zero,
            quantity: -1,
            sku: "T-SHIRT-NINJA-SILHOUETTE",
            total: currencyFormatter.convertToDecimal("-18.00") ?? NSDecimalNumber.zero,
            attributes: []
        )

        let item2 = AggregateOrderItem(
            itemID: "63",
            productID: 21,
            variationID: 71,
            name: "Ship Your Idea - Black, L",
            price: currencyFormatter.convertToDecimal("31.5") ?? NSDecimalNumber.zero,
            quantity: -1,
            sku: "HOODIE-SHIP-YOUR-IDEA-BLACK-L",
            total: currencyFormatter.convertToDecimal("-31.50") ?? NSDecimalNumber.zero,
            attributes: testOrderItemAttributes
        )

        let item3 = AggregateOrderItem(
            itemID: "64",
            productID: 16,
            variationID: 0,
            name: "Woo Logo",
            price: currencyFormatter.convertToDecimal("31.5") ?? NSDecimalNumber.zero,
            quantity: -2,
            sku: "HOODIE-WOO-LOGO",
            total: currencyFormatter.convertToDecimal("-63.00") ?? NSDecimalNumber.zero,
            attributes: []
        )

        let item4 = AggregateOrderItem(
            itemID: "65",
            productID: 21,
            variationID: 70,
            name: "Ship Your Idea - Blue, XL",
            price: currencyFormatter.convertToDecimal("27") ?? NSDecimalNumber.zero,
            quantity: -3,
            sku: "HOODIE-SHIP-YOUR-IDEA-BLUE-XL",
            total: currencyFormatter.convertToDecimal("-81.00") ?? NSDecimalNumber.zero,
            attributes: []
        )

        return [item0, item1, item2, item3, item4]
    }
}
