import Foundation
import XCTest

import Yosemite

import protocol Storage.StorageManagerType
import protocol Storage.StorageType

@testable import WooCommerce

/// Test cases for `OrderDetailsDataSourceTests`
///
final class OrderDetailsDataSourceTests: XCTestCase {

    private typealias Title = OrderDetailsDataSource.Title

    private var storageManager: StorageManagerType!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func testPaymentSectionIsShownRightAfterTheProductsAndRefundedProductsSections() {
        // Given
        let order = makeOrder()

        insert(refund: makeRefund(orderID: order.orderID, siteID: order.siteID))

        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager)
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let actualTitles = dataSource.sections.map(\.title)
        let expectedTitles = [
            nil,
            Title.product,
            Title.refundedProducts,
            Title.payment,
            Title.information,
            Title.notes
        ]

        XCTAssertEqual(actualTitles, expectedTitles)
    }

}

// MARK: - Test Data

private extension OrderDetailsDataSourceTests {
    func makeOrder() -> Order {
        Order(siteID: 1_000,
              orderID: 2_000,
              parentID: 0,
              customerID: 11,
              number: "963",
              statusKey: "processing",
              currency: "USD",
              customerNote: "",
              dateCreated: Date(),
              dateModified: Date(),
              datePaid: Date(),
              discountTotal: "30.00",
              discountTax: "1.20",
              shippingTotal: "0.00",
              shippingTax: "0.00",
              total: "31.20",
              totalTax: "1.20",
              paymentMethodTitle: "Credit Card (Stripe)",
              items: [makeOrderItem(), makeOrderItem()],
              billingAddress: nil,
              shippingAddress: nil,
              shippingLines: [],
              coupons: [],
              refunds: [])
    }

    func makeOrderItem() -> OrderItem {
        OrderItem(itemID: 1,
                  name: "Order Item Name",
                  productID: 1_00,
                  variationID: 0,
                  quantity: 1,
                  price: NSDecimalNumber(integerLiteral: 1),
                  sku: nil,
                  subtotal: "1",
                  subtotalTax: "1",
                  taxClass: "TaxClass",
                  taxes: [],
                  total: "1",
                  totalTax: "1")
    }

    func makeRefund(orderID: Int64, siteID: Int64) -> Refund {
        let orderItemRefund = OrderItemRefund(itemID: 1,
                                              name: "OrderItemRefund",
                                              productID: 1,
                                              variationID: 1,
                                              quantity: 1,
                                              price: NSDecimalNumber(integerLiteral: 1),
                                              sku: nil,
                                              subtotal: "1",
                                              subtotalTax: "1",
                                              taxClass: "TaxClass",
                                              taxes: [],
                                              total: "1",
                                              totalTax: "1")
        return Refund(refundID: 1,
                      orderID: orderID,
                      siteID: siteID,
                      dateCreated: Date(),
                      amount: "1",
                      reason: "Reason",
                      refundedByUserID: 1,
                      isAutomated: nil,
                      createAutomated: nil,
                      items: [orderItemRefund])
    }

    func insert(refund: Refund) {
        let storageOrderItemRefunds: Set<StorageOrderItemRefund> = Set(refund.items.map { orderItemRefund in
            let storageOrderItemRefund = storage.insertNewObject(ofType: StorageOrderItemRefund.self)
            storageOrderItemRefund.update(with: orderItemRefund)
            return storageOrderItemRefund
        })

        let storageRefund = storage.insertNewObject(ofType: StorageRefund.self)
        storageRefund.update(with: refund)
        storageRefund.addToItems(storageOrderItemRefunds as NSSet)
    }
}
