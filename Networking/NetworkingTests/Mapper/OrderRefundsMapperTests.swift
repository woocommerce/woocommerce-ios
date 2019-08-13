import XCTest
@testable import Networking


/// OrderRefundsMapper Unit Tests
///
final class OrderRefundsMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID = 33334444

    /// Verifies that all of the Order Refunds fields are parsed correctly.
    ///
    func testOrderRefundsFieldsAreProperlyParsed() {
        let orderRefunds = mapLoadAllOrderRefundsResponse()
        XCTAssertEqual(orderRefunds.count, 2)

        let firstOrderRefunds = orderRefunds[0]
        XCTAssertEqual(firstOrderRefunds.siteID, dummySiteID)
        XCTAssertEqual(firstOrderRefunds.refundID, 726)

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2017-03-21T20:07:11")
        XCTAssertEqual(firstOrderRefunds.dateCreated, dateCreated)

        XCTAssertEqual(firstOrderRefunds.amount, "10.00")
        XCTAssertEqual(firstOrderRefunds.reason, "Product No Longer Needed")
        XCTAssertEqual(firstOrderRefunds.refundedBy, 1)
        XCTAssertEqual(firstOrderRefunds.refundedPayment, false)
    }

    /// Verifies that all of the Order Refunds Items are parsed correctly.
    ///
    func testOrderRefundsItemsAreCorrectlyParsed() {
        let orderRefunds = mapLoadAllOrderRefundsResponse()

        let item = orderRefunds[0].items[0]
        XCTAssertEqual(item.itemID, 888)
        XCTAssertEqual(item.name, "Poster (Product Add-On)")
        XCTAssertEqual(item.productID, 956)
        XCTAssertEqual(item.quantity, 1)
        XCTAssertEqual(item.price, NSDecimalNumber(integerLiteral: 10))
        XCTAssertEqual(item.sku, "")
        XCTAssertEqual(item.subtotal, "10.00")
        XCTAssertEqual(item.subtotalTax, "0.00")
        XCTAssertEqual(item.taxClass, "")
        XCTAssertEqual(item.total, "10.00")
        XCTAssertEqual(item.totalTax, "0.00")
        XCTAssertEqual(item.variationID, 0)
    }
}


/// Private Methods.
///
private extension OrderRefundsMapperTests {

    /// Returns the OrderRefundsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrderRefunds(from filename: String) -> [OrderRefund] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! OrderRefundsMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the OrderRefundsMapper output upon receiving `order-refunds-list`
    ///
    func mapLoadAllOrderRefundsResponse() -> [OrderRefund] {
        return mapOrderRefunds(from: "order-refunds-list")
    }
}
