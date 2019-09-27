import XCTest
@testable import Networking


/// RefundsMapper Unit Tests
///
final class RefundsMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID = 33334444

    /// Verifies that all of the Order Refunds fields are parsed correctly.
    ///
    func testRefundFieldsAreProperlyParsed() {
        let refunds = mapLoadAllRefundsResponse()
        XCTAssertEqual(refunds.count, 2)

        let firstRefund = refunds[0]
        XCTAssertEqual(firstRefund.siteID, dummySiteID)
        XCTAssertEqual(firstRefund.refundID, 726)

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2017-03-21T20:07:11")
        XCTAssertEqual(firstRefund.dateCreated, dateCreated)

        XCTAssertEqual(firstRefund.amount, "10.00")
        XCTAssertEqual(firstRefund.reason, "Product No Longer Needed")
        XCTAssertEqual(firstRefund.refundedBy, 1)
        XCTAssertEqual(firstRefund.refundedPayment, false)
    }

    /// Verifies that all of the Refunded Order Items are parsed correctly.
    ///
    func testRefundItemsAreCorrectlyParsed() {
        let refunds = mapLoadAllRefundsResponse()

        let firstRefund = refunds[0]
        guard let item = firstRefund.items?.first else {
            XCTFail()
        }

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
private extension RefundsMapperTests {

    /// Returns the RefundsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapRefunds(from filename: String) -> [Refund] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! RefundsMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the RefundsMapper output upon receiving `refunds-list`
    ///
    func mapLoadAllRefundsResponse() -> [Refund] {
        return mapRefunds(from: "refunds-list")
    }
}
