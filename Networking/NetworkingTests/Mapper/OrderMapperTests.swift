import XCTest
@testable import Networking


/// OrderMapper Unit Tests
///
class OrderMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID = 424242


    /// Verifies that all of the Order Fields are parsed correctly.
    ///
    func testOrderFieldsAreProperlyParsed() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:12")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")
        let datePaid = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")

        XCTAssertEqual(order.siteID, dummySiteID)
        XCTAssertEqual(order.orderID, 963)
        XCTAssertEqual(order.parentID, 0)
        XCTAssertEqual(order.customerID, 11)
        XCTAssertEqual(order.number, "963")
        XCTAssert(order.statusKey == "processing")
        XCTAssertEqual(order.currency, "USD")
        XCTAssertEqual(order.customerNote, "")
        XCTAssertEqual(order.dateCreated, dateCreated)
        XCTAssertEqual(order.dateModified, dateModified)
        XCTAssertEqual(order.datePaid, datePaid)
        XCTAssertEqual(order.discountTotal, "30.00")
        XCTAssertEqual(order.discountTax, "1.20")
        XCTAssertEqual(order.shippingTotal, "0.00")
        XCTAssertEqual(order.shippingTax, "0.00")
        XCTAssertEqual(order.total, "31.20")
        XCTAssertEqual(order.totalTax, "1.20")
    }

    /// Verifies that all of the Order Address fields are parsed correctly.
    ///
    func testOrderAddressesAreCorrectlyParsed() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        let dummyAddresses = [order.shippingAddress, order.billingAddress].compactMap({ $0 })
        XCTAssertEqual(dummyAddresses.count, 2)

        for address in dummyAddresses {
            XCTAssertEqual(address.firstName, "Johnny")
            XCTAssertEqual(address.lastName, "Appleseed")
            XCTAssertEqual(address.company, "")
            XCTAssertEqual(address.address1, "234 70th Street")
            XCTAssertEqual(address.address2, "")
            XCTAssertEqual(address.city, "Niagara Falls")
            XCTAssertEqual(address.state, "NY")
            XCTAssertEqual(address.postcode, "14304")
            XCTAssertEqual(address.country, "US")
        }
    }

    /// Verifies that all of the Order Items are parsed correctly.
    ///
    func testOrderItemsAreCorrectlyParsed() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        let firstItem = order.items[0]
        XCTAssertEqual(firstItem.itemID, 890)
        XCTAssertEqual(firstItem.name, "Fruits Basket (Mix & Match Product)")
        XCTAssertEqual(firstItem.productID, 52)
        XCTAssertEqual(firstItem.quantity, 2)
        XCTAssertEqual(firstItem.price, NSDecimalNumber(integerLiteral: 30))
        XCTAssertEqual(firstItem.sku, "")
        XCTAssertEqual(firstItem.subtotal, "50.00")
        XCTAssertEqual(firstItem.subtotalTax, "2.00")
        XCTAssertEqual(firstItem.taxClass, "")
        XCTAssertEqual(firstItem.total, "30.00")
        XCTAssertEqual(firstItem.totalTax, "1.20")
        XCTAssertEqual(firstItem.variationID, 0)
    }

    /// Verifies that Order Items with a decimal quantity are parsed properly
    ///
    func testOrderItemsWithDecimalQuantityAreCorrectlyParsed() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        let secondItem = order.items[1]
        XCTAssertEqual(secondItem.itemID, 891)
        XCTAssertEqual(secondItem.quantity, 1.5)
    }

    /// Verifies that an Order in a broken state does [gets default values] | [gets skipped while parsing]
    ///
    func testOrderHasDefaultDateCreatedWhenNullDateReceived() {
        guard let brokenOrder = mapLoadBrokenOrderResponse() else {
            XCTFail()
            return
        }

        let format = DateFormatter()
        format.dateStyle = .short

        let orderCreatedString = format.string(from: brokenOrder.dateCreated)
        let todayCreatedString = format.string(from: Date())
        XCTAssertEqual(orderCreatedString, todayCreatedString)

        let orderModifiedString = format.string(from: brokenOrder.dateModified)
        XCTAssertEqual(orderModifiedString, todayCreatedString)
    }

    /// Verifies that the coupon fields for an Order are correctly parsed.
    ///
    func testOrderCouponFieldsAreCorrectlyParsed() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        XCTAssertNotNil(order.coupons)
        XCTAssertEqual(order.coupons.count, 1)

        guard let coupon = order.coupons.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(coupon.couponID, 894)
        XCTAssertEqual(coupon.code, "30$off")
        XCTAssertEqual(coupon.discount, "30")
        XCTAssertEqual(coupon.discountTax, "1.2")
    }

    /// Verifies that an Order with no refunds is correctly parsed to an empty array.
    ///
    func testOrderRefundCondensedFieldsDoNotExistAreParsedCorrectly() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(order.refunds, [])
    }

    /// Verifies that an Order with refund fields are correctly parsed.
    ///
    func testOrderFullRefundFieldsAreParsedCorrectly() {
        guard let order = mapLoadFullyRefundedOrderResponse() else {
            XCTFail()
            return
        }

        let refunds = order.refunds
        XCTAssertEqual(refunds.count, 1)

        guard let fullRefund = refunds.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(fullRefund.refundID, 622)
        XCTAssertEqual(fullRefund.reason, "Order fully refunded")
        XCTAssertEqual(fullRefund.total, "-223.71")
    }

    /// Verifies that an Order with multiple, partial refunds have the refunds fields correctly parsed.
    ///
    func testOrderPartialRefundFieldsAreParsedCorrectly() {
        guard let order = mapLoadPartiallRefundedOrderResponse() else {
            XCTFail()
            return
        }

        let refunds = order.refunds
        XCTAssertEqual(refunds.count, 2)

        let partialRefund1 = refunds[0]
        XCTAssertEqual(partialRefund1.refundID, 549)
        XCTAssertEqual(partialRefund1.reason, "Sold out")
        XCTAssertEqual(partialRefund1.total, "-16.20")

        let partialRefund2 = refunds[1]
        XCTAssertEqual(partialRefund2.refundID, 547)
        XCTAssertEqual(partialRefund2.reason, "")
        XCTAssertEqual(partialRefund2.total, "-8.10")
    }
}


/// Private Methods.
///
private extension OrderMapperTests {

    /// Returns the OrderMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrder(from filename: String) -> Order? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! OrderMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the OrderMapper output upon receiving `order`
    ///
    func mapLoadOrderResponse() -> Order? {
        return mapOrder(from: "order")
    }

    /// Returns the OrderMapper output upon receiving `broken-order`
    ///
    func mapLoadBrokenOrderResponse() -> Order? {
        return mapOrder(from: "broken-order")
    }

    /// Returns the OrderMapper output upon receiving `order-fully-refunded`
    ///
    func mapLoadFullyRefundedOrderResponse() -> Order? {
        return mapOrder(from: "order-fully-refunded")
    }

    /// Returns the OrderMapper output upon receiving `order-details-partially-refunded`
    ///
    func mapLoadPartiallRefundedOrderResponse() -> Order? {
        return mapOrder(from: "order-details-partially-refunded")
    }
}
