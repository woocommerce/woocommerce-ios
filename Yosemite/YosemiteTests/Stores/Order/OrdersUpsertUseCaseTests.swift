import XCTest

import Storage
import Networking

@testable import Yosemite

final class OrdersUpsertUseCaseTests: XCTestCase {

    private let defaultSiteID: Int64 = 10
    private var storageManager: StorageManagerType!
    private var viewStorage: StorageType {
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

    func test_it_inserts_orders_with_permanent_ids() throws {
        // Given
        let orders = [makeOrder(), makeOrder()]
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        let storageOrders = useCase.upsert(orders)

        // Then
        XCTAssertEqual(storageOrders.count, 2)
        storageOrders.forEach { storageOrder in
            XCTAssertFalse(storageOrder.objectID.isTemporaryID)
        }
    }

    func test_it_persists_orders_in_storage() throws {
        // Given
        let orders = [
            makeOrder().copy(orderID: 98, number: "dignissimos"),
            makeOrder().copy(orderID: 9001, number: "omnis"),
        ]
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert(orders)

        // Then
        let persistedOrder98 = try XCTUnwrap(viewStorage.loadOrder(siteID: defaultSiteID, orderID: 98))
        XCTAssertEqual(persistedOrder98.toReadOnly(), orders.first)

        let persistedOrder9001 = try XCTUnwrap(viewStorage.loadOrder(siteID: defaultSiteID, orderID: 9001))
        XCTAssertEqual(persistedOrder9001.toReadOnly(), orders.last)
    }

    func test_it_persists_order_relationships_in_storage() throws {
        // Given
        let coupon = Networking.OrderCouponLine(couponID: 1, code: "", discount: "", discountTax: "")
        let refund = Networking.OrderRefundCondensed(refundID: 122, reason: "", total: "1.6")
        let shippingLine = Networking.ShippingLine(shippingID: 25, methodTitle: "dodo", methodID: "", total: "2.1", totalTax: "0.8")
        let order = makeOrder().copy(orderID: 98, number: "dignissimos", shippingLines: [shippingLine], coupons: [coupon], refunds: [refund])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let persistedOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: defaultSiteID, orderID: 98))
        XCTAssertEqual(persistedOrder.toReadOnly(), order)
        let persistedCoupon = try XCTUnwrap(viewStorage.loadOrderCoupon(siteID: defaultSiteID, couponID: coupon.couponID))
        XCTAssertEqual(persistedCoupon.toReadOnly(), coupon)
        let persistedRefund = try XCTUnwrap(viewStorage.loadOrderRefundCondensed(siteID: defaultSiteID, refundID: refund.refundID))
        XCTAssertEqual(persistedRefund.toReadOnly(), refund)
        let persistedShippingLine = try XCTUnwrap(viewStorage.loadShippingLine(siteID: defaultSiteID, shippingID: shippingLine.shippingID))
        XCTAssertEqual(persistedShippingLine.toReadOnly(), shippingLine)
    }
}

private extension OrdersUpsertUseCaseTests {
    func makeOrder() -> Networking.Order {
        Order(siteID: defaultSiteID,
              orderID: 0,
              parentID: 0,
              customerID: 0,
              number: "",
              status: .custom(""),
              currency: "",
              customerNote: nil,
              dateCreated: Date(),
              dateModified: Date(),
              datePaid: nil,
              discountTotal: "",
              discountTax: "",
              shippingTotal: "",
              shippingTax: "",
              total: "",
              totalTax: "",
              paymentMethodTitle: "",
              items: [],
              billingAddress: nil,
              shippingAddress: nil,
              shippingLines: [],
              coupons: [],
              refunds: [])
    }
}
