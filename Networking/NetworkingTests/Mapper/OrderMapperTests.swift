import XCTest
@testable import Networking


/// OrderMapper Unit Tests
///
class OrderMapperTests: XCTestCase {

    /// Verifies that all of the Order Fields are parsed correctly.
    ///
    func testOrderFieldsAreProperlyParsed() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-01-24T16:21:48")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-05-09T18:15:30")
        let datePaid = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-05-03T19:24:55")

        XCTAssertEqual(order.orderID, 1467)
        XCTAssertEqual(order.parentID, 0)
        XCTAssertEqual(order.customerID, 100)
        XCTAssertEqual(order.number, "1467")
        XCTAssert(order.status == .processing)
        XCTAssertEqual(order.currency, "USD")
        XCTAssertEqual(order.customerNote, "")
        XCTAssertEqual(order.dateCreated, dateCreated)
        XCTAssertEqual(order.dateModified, dateModified)
        XCTAssertEqual(order.datePaid, datePaid)
        XCTAssertEqual(order.discountTotal, "0.00")
        XCTAssertEqual(order.discountTax, "0.00")
        XCTAssertEqual(order.shippingTotal, "0.00")
        XCTAssertEqual(order.shippingTax, "0.00")
        XCTAssertEqual(order.total, "102.00")
        XCTAssertEqual(order.totalTax, "2.00")
    }

    /// Verifies that all of the Order Address fields are parsed correctly.
    ///
    func testOrderAddressesAreCorrectlyParsed() {
        guard let order = mapLoadOrderResponse() else {
            XCTFail()
            return
        }

        let dummyAddresses = [order.billingAddress, order.shippingAddress]

        for address in dummyAddresses {
            XCTAssertEqual(address.firstName, "Maria")
            XCTAssertEqual(address.lastName, "Scrambled")
            XCTAssertEqual(address.company, "Logged Out")
            XCTAssertEqual(address.address1, "9999 Scrambled")
            XCTAssertEqual(address.address2, "")
            XCTAssertEqual(address.city, "Omaha")
            XCTAssertEqual(address.state, "NE")
            XCTAssertEqual(address.postcode, "68124")
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
        XCTAssertEqual(firstItem.itemID, 3)
        XCTAssertEqual(firstItem.name, "ARC Reactor")
        XCTAssertEqual(firstItem.productID, 1450)
        XCTAssertEqual(firstItem.quantity, 1)
        XCTAssertEqual(firstItem.sku, "100")
        XCTAssertEqual(firstItem.subtotal, "100.00")
        XCTAssertEqual(firstItem.subtotalTax, "2.00")
        XCTAssertEqual(firstItem.taxClass, "")
        XCTAssertEqual(firstItem.total, "100.00")
        XCTAssertEqual(firstItem.totalTax, "2.00")
        XCTAssertEqual(firstItem.variationID, 0)
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
}


/// Private Methods.
///
private extension OrderMapperTests {

    /// Returns the OrderListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrder(from filename: String) -> Order? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! OrderMapper().map(response: response)
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
}
