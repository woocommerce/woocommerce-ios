import XCTest
@testable import Networking


/// OrderMapper Unit Tests
///
final class OrderMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 424242


    /// Verifies that all of the Order Fields are parsed correctly.
    ///
    func test_Order_fields_are_properly_parsed() {
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
        XCTAssertEqual(order.status, .processing)
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
    func test_Order_addresses_are_correctly_parsed() {
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
    func test_Order_items_are_correctly_parsed() {
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
    func test_Order_items_with_decimal_quantity_are_correctly_parsed() {
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
    func test_Order_has_default_dateCreated_when_null_date_received() {
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
    func test_Order_coupon_fields_are_correctly_parsed() {
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
    func test_Order_refund_condensed_fields_do_not_exist_are_parsed_correctly() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(order.refunds, [])
    }

    /// Verifies that an Order with refund fields are correctly parsed.
    ///
    func test_Order_full_refund_fields_are_parsed_correctly() {
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
    func test_Order_partial_refund_fields_are_parsed_correctly() {
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

    /// Verifies that an Order ignores deleted refunds.
    ///
    func test_Order_deleted_refund_fields_are_ignored() throws {
        // When
        let order = try XCTUnwrap(mapLoadOrderWithDeletedRefundsResponse())

        // Then
        XCTAssertEqual(order.refunds.count, 1)

        let refund = try XCTUnwrap(order.refunds.first)
        XCTAssertEqual(refund.refundID, 73)
        XCTAssertEqual(refund.reason, "Cap!")
        XCTAssertEqual(refund.total, "-16.00")
    }

    func test_taxes_are_parsed_correctly() throws {
        // When
        let order = try XCTUnwrap(mapLoadOrderResponse())
        let shippingLine = try XCTUnwrap(order.shippingLines.first)

        // Then
        let expectedTax = ShippingLineTax(taxID: 1, subtotal: "", total: "0.62125")
        XCTAssertEqual(shippingLine.taxes, [expectedTax])
    }

    func test_OrderLineItem_attributes_are_parsed_correctly() throws {
        let order = try XCTUnwrap(mapLoadOrderWithLineItemAttributesResponse())

        let lineItems = order.items
        XCTAssertEqual(lineItems.count, 2)

        let variationLineItem = lineItems[0]
        // Attributes with `_` prefix in the name are skipped.
        let expectedAttributes: [OrderItemAttribute] = [
            .init(metaID: 6377, name: "Color", value: "Orange"),
            .init(metaID: 6378, name: "Brand", value: "Woo")
        ]
        XCTAssertEqual(variationLineItem.attributes, expectedAttributes)
        // `parent_name` is used instead of `name` in the API line item response.
        XCTAssertEqual(variationLineItem.name, "<Variable> Fun Pens!")

        let productLineItem = lineItems[1]
        XCTAssertEqual(productLineItem.attributes, [])
        XCTAssertEqual(productLineItem.name, "(Downloadable) food")
    }

    /// The attributes API support are added in WC version 4.7, and WC version 4.6.1 returns a different structure of order line item attributes.
    func test_OrderLineItem_attributes_are_empty_before_API_support() throws {
        let order = try XCTUnwrap(mapLoadOrderWithLineItemAttributesBeforeAPISupportResponse())

        let lineItems = order.items
        XCTAssertEqual(lineItems.count, 1)

        let variationLineItem = lineItems[0]
        XCTAssertEqual(variationLineItem.attributes, [])
        XCTAssertEqual(variationLineItem.name, "Hoodie - Green, No")
    }

    func test_Order_fees_are_correctly_parsed() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        XCTAssertNotNil(order.fees)
        XCTAssertEqual(order.fees.count, 1)

        guard let fee = order.fees.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(fee.feeID, 60)
        XCTAssertEqual(fee.name, "$125.50 fee")
        XCTAssertEqual(fee.taxClass, "")
        XCTAssertEqual(fee.taxStatus, .taxable)
        XCTAssertEqual(fee.total, "125.50")
        XCTAssertEqual(fee.totalTax, "0.00")
        XCTAssertEqual(fee.taxes, [])
        XCTAssertEqual(fee.attributes, [])
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

    /// Returns the OrderMapper output upon receiving `order-with-line-item-attributes`
    ///
    func mapLoadOrderWithLineItemAttributesResponse() -> Order? {
        return mapOrder(from: "order-with-line-item-attributes")
    }

    /// Returns the OrderMapper output upon receiving `order-with-line-item-attributes-before-API-support`
    ///
    func mapLoadOrderWithLineItemAttributesBeforeAPISupportResponse() -> Order? {
        return mapOrder(from: "order-with-line-item-attributes-before-API-support")
    }

    /// Returns the OrderMapper output upon receiving `order-with-deleted-refunds`
    ///
    func mapLoadOrderWithDeletedRefundsResponse() -> Order? {
        return mapOrder(from: "order-with-deleted-refunds")
    }

}
