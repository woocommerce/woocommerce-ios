import XCTest
@testable import Networking


/// RefundMapper Unit Tests
///
final class RefundMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID = 33334444

    /// Order ID.
    ///
    private let orderID = 560

    /// Verifies that all of the Refund fields are parsed correctly.
    ///
    func testRefundFieldsAreProperlyParsed() {
        guard let refund = mapLoadRefundResponse() else {
            XCTFail("No `refund-single.json` file found.")
            return
        }

        XCTAssertEqual(refund.siteID, dummySiteID)
        XCTAssertEqual(refund.refundID, 562)

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-01T19:33:46")
        XCTAssertEqual(refund.dateCreated, dateCreated)

        XCTAssertEqual(refund.amount, "27.00")
        XCTAssertEqual(refund.reason, "My pet hamster ate the sleeve off of one of the Blue XL hoodies. Sorry! No longer for sale.")
        XCTAssertEqual(refund.refundedByUserID, 1)
        XCTAssertEqual(refund.isAutomated, true)
    }

    /// Verifies that all of the Refunded Order Items are parsed correctly.
    ///
    func testRefundItemsAreCorrectlyParsed() {
        guard let refund = mapLoadRefundResponse() else {
            XCTFail("Failed to load `refund-single.json` file.")
            return
        }

        guard let item = refund.items.first else {
            XCTFail("Failed to load `refund-single.json` file")
            return
        }

        XCTAssertEqual(item.itemID, 67)
        XCTAssertEqual(item.name, "Ship Your Idea - Blue, XL")
        XCTAssertEqual(item.productID, 21)
        XCTAssertEqual(item.variationID, 70)
        XCTAssertEqual(item.quantity, -1)
        XCTAssertEqual(item.subtotal, "-27.00")
        XCTAssertEqual(item.subtotalTax, "0.00")
        XCTAssertEqual(item.taxClass, "")
        XCTAssertEqual(item.taxes, [])
        XCTAssertEqual(item.total, "-27.00")
        XCTAssertEqual(item.totalTax, "0.00")
        XCTAssertEqual(item.sku, "HOODIE-SHIP-YOUR-IDEA-BLUE-XL")
        XCTAssertEqual(item.price, NSDecimalNumber(integerLiteral: 27))
    }
}


/// Private Methods.
///
private extension RefundMapperTests {

    /// Returns the RefundMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapRefund(from filename: String) -> Refund? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! RefundMapper(siteID: dummySiteID, orderID: orderID).map(response: response)
    }

    /// Returns the RefundsMapper output upon receiving `refund-single`
    ///
    func mapLoadRefundResponse() -> Refund? {
        return mapRefund(from: "refund-single")
    }
}
