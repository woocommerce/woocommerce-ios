import XCTest
@testable import Networking


/// RefundListMapper Unit Tests
///
final class RefundListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID = 90210

    /// Order ID.
    ///
    private let orderID = 560

    /// Verifies that all the Refund fields are parsed correctly.
    ///
    func testRefundFieldsAreProperlyParsed() {
        let refunds = mapLoadAllRefundsResponse()
        XCTAssertEqual(refunds.count, 2)

        let firstRefund = refunds[0]
        XCTAssertEqual(firstRefund.siteID, dummySiteID)
        XCTAssertEqual(firstRefund.orderID, orderID)
        XCTAssertEqual(firstRefund.refundID, 590)

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-09T16:18:23")
        XCTAssertEqual(firstRefund.dateCreated, dateCreated)

        XCTAssertEqual(firstRefund.amount, "18.00")
        XCTAssertEqual(firstRefund.reason, "Only 1 black hoodie left. Inventory count was off. My bad!")
        XCTAssertEqual(firstRefund.refundedByUserID, 1)

        if let isAutomated = firstRefund.isAutomated {
            XCTAssertTrue(isAutomated)
        }

        let secondRefund = refunds[1]
        XCTAssertEqual(secondRefund.siteID, dummySiteID)
        XCTAssertEqual(secondRefund.orderID, orderID)
        XCTAssertEqual(secondRefund.refundID, 562)

        let dateCreated2 = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-01T19:33:46")
        XCTAssertEqual(secondRefund.dateCreated, dateCreated2)

        XCTAssertEqual(secondRefund.amount, "27.00")
        XCTAssertEqual(secondRefund.reason, "My pet hamster ate the sleeve off of one of the Blue XL hoodies. Sorry! No longer for sale.")
        XCTAssertEqual(secondRefund.refundedByUserID, 1)

        if let isAutomated = secondRefund.isAutomated {
            XCTAssertTrue(isAutomated)
        }
    }

    /// Verifies that all of the Refunded Order Items are parsed correctly.
    ///
    func testRefundItemsAreCorrectlyParsed() {
        let refunds = mapLoadAllRefundsResponse()
        XCTAssertEqual(refunds.count, 2)

        let refund = refunds[0]
        guard let item = refund.items.first else {
            XCTFail("Failed to load `refunds-all.json` file")
            return
        }
        XCTAssertEqual(refund.items.count, 1)

        XCTAssertEqual(item.itemID, 73)
        XCTAssertEqual(item.name, "Ninja Silhouette")
        XCTAssertEqual(item.productID, 22)
        XCTAssertEqual(item.variationID, 0)
        XCTAssertEqual(item.quantity, -1)
        XCTAssertEqual(item.subtotal, "-18.00")
        XCTAssertEqual(item.subtotalTax, "0.00")
        XCTAssertEqual(item.taxClass, "")
        XCTAssertEqual(item.taxes, [])
        XCTAssertEqual(item.total, "-18.00")
        XCTAssertEqual(item.totalTax, "0.00")
        XCTAssertEqual(item.sku, "T-SHIRT-NINJA-SILHOUETTE")
        XCTAssertEqual(item.price, NSDecimalNumber(integerLiteral: 18))

        let refund2 = refunds[1]
        guard let item2 = refund2.items.first else {
            XCTFail("Failed to load `refunds-all.json` file")
            return
        }
        XCTAssertEqual(refund2.items.count, 1)

        XCTAssertEqual(item2.itemID, 67)
        XCTAssertEqual(item2.name, "Ship Your Idea - Blue, XL")
        XCTAssertEqual(item2.productID, 21)
        XCTAssertEqual(item2.variationID, 70)
        XCTAssertEqual(item2.quantity, -1)
        XCTAssertEqual(item2.subtotal, "-27.00")
        XCTAssertEqual(item2.subtotalTax, "0.00")
        XCTAssertEqual(item2.taxClass, "")
        XCTAssertEqual(item2.taxes, [])
        XCTAssertEqual(item2.total, "-27.00")
        XCTAssertEqual(item2.totalTax, "0.00")
        XCTAssertEqual(item2.sku, "HOODIE-SHIP-YOUR-IDEA-BLUE-XL")
        XCTAssertEqual(item2.price, NSDecimalNumber(integerLiteral: 27))
    }

    /// Verifies that a created refund object is encoded properly.
    ///
    func testRefundIsEncodedProperly() {
        // test to come in future updates.
    }
}


/// Private Methods.
///
private extension RefundListMapperTests {

    /// Returns the RefundListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapRefunds(from filename: String) -> [Refund] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! RefundListMapper(siteID: dummySiteID, orderID: orderID).map(response: response)
    }

    /// Returns the RefundListMapper output upon receiving `refunds-all`
    ///
    func mapLoadAllRefundsResponse() -> [Refund] {
        return mapRefunds(from: "refunds-all")
    }
}
