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

        testAddressWasCorrectlyParsed(firstOrder.billingAddress)
        testAddressWasCorrectlyParsed(firstOrder.shippingAddress)
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

    /// Verifies that a given Address instance contains a Dummy Payload.
    ///
    func testAddressWasCorrectlyParsed(_ address: Address) {
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
