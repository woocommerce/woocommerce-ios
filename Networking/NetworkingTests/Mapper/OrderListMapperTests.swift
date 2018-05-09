import XCTest
@testable import Networking


/// OrderListMapper Unit Tests
///
class OrderListMapperTests: XCTestCase {

    /// Verifies that all of the Order Fields are parsed correctly.
    ///
    func testOrderFieldsAreProperlyParsed() {
        let orders = mapLoadAllOrdersResponse()
        XCTAssert(orders.count == 3)

        let firstOrder = orders[0]
        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:12")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")
        let datePaid = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")

        XCTAssertEqual(firstOrder.orderID, 963)
        XCTAssertEqual(firstOrder.parentID, 0)
        XCTAssertEqual(firstOrder.customerID, 11)
        XCTAssertEqual(firstOrder.number, "963")
        XCTAssert(firstOrder.status == .processing)
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

    /// Verifies that all of the Order Address fields are parsed correctly.
    ///
    func testOrderAddressesAreCorrectlyParsed() {
        let orders = mapLoadAllOrdersResponse()
        XCTAssert(orders.count == 3)

        let firstOrder = orders[0]
        let dummyAddresses = [firstOrder.billingAddress, firstOrder.shippingAddress]

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
        let order = mapLoadAllOrdersResponse()[0]
        XCTAssertEqual(order.items.count, 2)

        let firstItem = order.items[0]
        XCTAssertEqual(firstItem.itemID, 890)
        XCTAssertEqual(firstItem.name, "Fruits Basket (Mix & Match Product)")
        XCTAssertEqual(firstItem.productID, 52)
        XCTAssertEqual(firstItem.quantity, 1)
        XCTAssertEqual(firstItem.sku, "")
        XCTAssertEqual(firstItem.subtotal, "50.00")
        XCTAssertEqual(firstItem.subtotalTax, "2.00")
        XCTAssertEqual(firstItem.taxClass, "")
        XCTAssertEqual(firstItem.total, "30.00")
        XCTAssertEqual(firstItem.totalTax, "1.20")
        XCTAssertEqual(firstItem.variationID, 0)
    }
}


/// Private Methods.
///
private extension OrderListMapperTests {

    /// Returns the OrderListMapper output upon receiving `orders-load-all` (Data Encoded)
    ///
    func mapLoadAllOrdersResponse() -> [Order] {
        guard let response = Loader.contentsOf("orders-load-all") else {
            return []
        }

        return try! OrderListMapper().map(response: response)
    }
}
