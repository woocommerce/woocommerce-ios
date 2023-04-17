import XCTest
@testable import Networking


/// OrderListMapper Unit Tests
///
class OrderListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 242424


    /// Verifies that all of the Order Fields are parsed correctly.
    ///
    func test_order_fields_are_properly_parsed() {
        let orders = mapLoadAllOrdersResponse()
        XCTAssert(orders.count == 4)

        let firstOrder = orders[0]
        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:12")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")
        let datePaid = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")

        XCTAssertEqual(firstOrder.orderID, 963)
        XCTAssertEqual(firstOrder.parentID, 0)
        XCTAssertEqual(firstOrder.customerID, 11)
        XCTAssertEqual(firstOrder.number, "963")
        XCTAssertEqual(firstOrder.status, .processing)
        XCTAssertEqual(firstOrder.currency, "USD")
        XCTAssertEqual(firstOrder.customerNote, "")
        XCTAssertEqual(firstOrder.dateCreated, dateCreated)
        XCTAssertEqual(firstOrder.dateModified, dateModified)
        XCTAssertEqual(firstOrder.datePaid, datePaid)
        XCTAssertEqual(firstOrder.discountTotal, "30.00")
        XCTAssertEqual(firstOrder.discountTax, "1.20")
        XCTAssertEqual(firstOrder.shippingTotal, "0.00")
        XCTAssertEqual(firstOrder.shippingTax, "0.00")
        XCTAssertEqual(firstOrder.total, "31.20")
        XCTAssertEqual(firstOrder.totalTax, "1.20")
    }

    /// Verifies that all of the Order Fields are parsed correctly when the response has no data envelope.
    ///
    func test_order_fields_are_properly_parsed_when_the_response_has_no_data_envelope() {
        let orders = mapLoadAllOrdersResponseWithoutDataEnvelope()
        XCTAssert(orders.count == 1)

        let firstOrder = orders[0]
        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:12")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")
        let datePaid = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")

        XCTAssertEqual(firstOrder.orderID, 963)
        XCTAssertEqual(firstOrder.parentID, 0)
        XCTAssertEqual(firstOrder.customerID, 11)
        XCTAssertEqual(firstOrder.number, "963")
        XCTAssertEqual(firstOrder.status, .processing)
        XCTAssertEqual(firstOrder.currency, "USD")
        XCTAssertEqual(firstOrder.customerNote, "")
        XCTAssertEqual(firstOrder.dateCreated, dateCreated)
        XCTAssertEqual(firstOrder.dateModified, dateModified)
        XCTAssertEqual(firstOrder.datePaid, datePaid)
        XCTAssertEqual(firstOrder.discountTotal, "30.00")
        XCTAssertEqual(firstOrder.discountTax, "1.20")
        XCTAssertEqual(firstOrder.shippingTotal, "0.00")
        XCTAssertEqual(firstOrder.shippingTax, "0.00")
        XCTAssertEqual(firstOrder.total, "31.20")
        XCTAssertEqual(firstOrder.totalTax, "1.20")
    }

    /// Verifies that the siteID field is properly set.
    ///
    func test_site_identifier_is_properly_injected_into_every_order() {
        for order in mapLoadAllOrdersResponse() {
            XCTAssertEqual(order.siteID, dummySiteID)
        }
    }

    /// Verifies that all of the Order Address fields are parsed correctly.
    ///
    func test_order_addresses_are_correctly_parsed() {
        let orders = mapLoadAllOrdersResponse()
        XCTAssert(orders.count == 4)

        let firstOrder = orders[0]
        var dummyAddresses = [Address]()
        if let shippingAddress = firstOrder.shippingAddress {
            dummyAddresses.append(shippingAddress)
        }

        if let billingAddress = firstOrder.billingAddress {
            dummyAddresses.append(billingAddress)
        }

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
    func test_order_items_are_correctly_parsed() {
        let order = mapLoadAllOrdersResponse()[0]
        XCTAssertEqual(order.items.count, 2)

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

    /// Verifies that an Order in a broken state does [gets default values] | [gets skipped while parsing]
    ///
    func test_order_has_default_date_created_when_null_date_received() {
        let orders = mapLoadBrokenOrderResponse()
        XCTAssert(orders.count == 1)

        let brokenOrder = orders[0]
        let format = DateFormatter()
        format.dateStyle = .short

        let orderCreatedString = format.string(from: brokenOrder.dateCreated)
        let todayCreatedString = format.string(from: Date())
        XCTAssertEqual(orderCreatedString, todayCreatedString)

        let orderModifiedString = format.string(from: brokenOrder.dateModified)
        XCTAssertEqual(orderModifiedString, todayCreatedString)
    }

    /// Verifies that `broken-orders-mark-2` gets properly parsed: 6 Orders with 2 items each, and the SKU property should
    /// always be set to null.
    ///
    /// Ref. Issue: https://github.com/woocommerce/woocommerce-ios/issues/221
    ///
    func test_order_list_with_breaking_format_is_properly_parsed() {
        let orders = mapLoadBrokenOrdersResponseMarkII()
        XCTAssertEqual(orders.count, 6)

        for order in orders {
            XCTAssertEqual(order.items.count, 2)

            for item in order.items {
                XCTAssertNil(item.sku)
            }
        }
    }
}


/// Private Methods.
///
private extension OrderListMapperTests {

    /// Returns the [Order] output upon receiving `filename` (Data Encoded)
    ///
    func mapOrders(siteID: Int64, from filename: String) -> [Order] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! OrderListMapper(siteID: siteID).map(response: response)
    }

    /// Returns the [Order] output upon receiving `orders-load-all`
    ///
    func mapLoadAllOrdersResponse() -> [Order] {
        return mapOrders(siteID: dummySiteID, from: "orders-load-all")
    }

    /// Returns the [Order] output upon receiving `orders-load-all-without-data`
    ///
    func mapLoadAllOrdersResponseWithoutDataEnvelope() -> [Order] {
        return mapOrders(siteID: WooConstants.placeholderSiteID, from: "orders-load-all-without-data")
    }

    /// Returns the [Order] output upon receiving `broken-order`
    ///
    func mapLoadBrokenOrderResponse() -> [Order] {
        return mapOrders(siteID: dummySiteID, from: "broken-orders")
    }

    /// Returns the [Order] output upon receiving `broken-orders-mark-2`
    ///
    func mapLoadBrokenOrdersResponseMarkII() -> [Order] {
        return mapOrders(siteID: dummySiteID, from: "broken-orders-mark-2")
    }
}
