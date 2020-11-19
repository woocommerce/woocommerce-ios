import XCTest
@testable import Networking


/// RefundMapper Unit Tests
///
final class RefundMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Order ID.
    ///
    private let orderID: Int64 = 560

    /// Verifies that all of the Refund fields are parsed correctly.
    ///
    func test_Refund_fields_are_properly_parsed() {
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
    func test_Refund_items_are_correctly_parsed() {
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

    func test_refund_shipping_lines_are_correctly_parsed() {
        guard let refund = mapLoadRefundResponse(),
              let shippingLine = refund.shippingLines?.first,
              let taxLine = shippingLine.taxes.first else {
            XCTFail("Failed to load `refund-single.json` file.")
            return
        }

        XCTAssertEqual(shippingLine.shippingID, 189)
        XCTAssertEqual(shippingLine.methodTitle, "Flat rate")
        XCTAssertEqual(shippingLine.methodID, "flat_rate")
        XCTAssertEqual(shippingLine.total, "-7.00")
        XCTAssertEqual(shippingLine.totalTax, "-0.62")
        XCTAssertEqual(taxLine.taxID, 1)
        XCTAssertEqual(taxLine.total, "-0.62")
        XCTAssertEqual(taxLine.subtotal, "")
    }

    func test_refund_is_encoded_correctly_with_items_and_taxes() throws {
        // Given
        let refund = sampleRefund(includeTaxes: true)
        let mapper = RefundMapper(siteID: dummySiteID, orderID: 123)

        // Ref:  https://git.io/JTRsF
        let expectedDictionary: [String: Any] = [
            "amount": refund.amount,
            "api_refund": refund.createAutomated ?? false,
            "reason": refund.reason,
            "line_items": [
                "\(refund.items[0].itemID)": [
                    "qty": refund.items[0].quantity,
                    "refund_total": refund.items[0].total,
                    "refund_tax": [
                        "\(refund.items[0].taxes[0].taxID)": refund.items[0].taxes[0].total
                    ]
                ]
            ]
        ]

        // When
        let refundEncoded = try mapper.map(refund: refund)
        let refundDictionary = try JSONSerialization.jsonObject(with: refundEncoded, options: []) as? [String: Any]

        // Then
        let dictionaryEquals = NSDictionary(dictionary: refundDictionary ?? [:]).isEqual(to: expectedDictionary)
        XCTAssertTrue(dictionaryEquals)
    }

    func test_refund_is_encoded_correctly_with_items_and_no_taxes() throws {
        // Given
        let refund = sampleRefund(includeTaxes: false)
        let mapper = RefundMapper(siteID: dummySiteID, orderID: 123)

        // Ref:  https://git.io/JTRsF
        let expectedDictionary: [String: Any] = [
            "amount": refund.amount,
            "api_refund": refund.createAutomated ?? false,
            "reason": refund.reason,
            "line_items": [
                "\(refund.items[0].itemID)": [
                    "qty": refund.items[0].quantity,
                    "refund_total": refund.items[0].total,
                    "refund_tax": [:]
                ]
            ]
        ]

        // When
        let refundEncoded = try mapper.map(refund: refund)
        let refundDictionary = try JSONSerialization.jsonObject(with: refundEncoded, options: []) as? [String: Any]

        // Then
        let dictionaryEquals = NSDictionary(dictionary: refundDictionary ?? [:]).isEqual(to: expectedDictionary)
        XCTAssertTrue(dictionaryEquals)
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

    /// Creates a dummy refund with items and taxes
    ///
    func sampleRefund(includeTaxes: Bool) -> Refund {
        Refund(refundID: 1,
               orderID: 1,
               siteID: dummySiteID,
               dateCreated: Date(),
               amount: "19.60",
               reason: "Some Reason",
               refundedByUserID: 1,
               isAutomated: nil,
               createAutomated: false,
               items: [sampleItem(includeTaxes: includeTaxes)],
               shippingLines: [])
    }

    /// Creates a dummy refund items with taxes
    ///
    func sampleItem(includeTaxes: Bool) -> OrderItemRefund {
        let taxes = includeTaxes ? [OrderItemTaxRefund(taxID: 1, subtotal: "1.60", total: "1.60")] : []
        return OrderItemRefund(itemID: 19,
                               name: "",
                               productID: 1,
                               variationID: 1,
                               quantity: 1,
                               price: 18.0,
                               sku: nil,
                               subtotal: "18.0",
                               subtotalTax: "1.60",
                               taxClass: "",
                               taxes: taxes,
                               total: "18.0",
                               totalTax: "1.60")
    }
}
