import XCTest
@testable import Networking


/// Refund Unit Tests
///
final class RefundTests: XCTestCase {

    func testFullRefund() {
        let expectation = dictionaryFullRefund()

        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", items: nil)
        let refundDict = refund.toDictionary()

        XCTAssert(NSDictionary(dictionary: expectation).isEqual(to: refundDict))
    }

    func testPartialRefundForSingleProductIncludingTax() {
        let expectation = dictionaryRefundForSingleProductIncludingTax()

        let itemRefund = LineItemRefund(itemID: "123", quantity: 1, refundTotal: "8.00", refundTax: [TaxRefund(taxIDLineItem: "789", amount: "2.00")])
        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", items: [itemRefund])
        let refundDict = refund.toDictionary()

        XCTAssert(NSDictionary(dictionary: expectation).isEqual(to: refundDict))
    }

    func testPartialRefundForSingleProductOnlyTax() {
        let expectation: [String: Any] = dictionaryPartialRefundForSingleProductOnlyTax()

        let itemRefund = LineItemRefund(itemID: "123", quantity: 1, refundTotal: nil, refundTax: [TaxRefund(taxIDLineItem: "789", amount: "2.00")])
        let refund = Refund(amount: "2.00", reason: nil, items: [itemRefund])
        let refundDict = refund.toDictionary()

        XCTAssert(NSDictionary(dictionary: expectation).isEqual(to: refundDict))
    }

    func testPartialRefundForSingleProductExcludingTax() {
        let expectation: [String: Any] = ["amount": "10.00",
                                           "api_refund": false,
                                           "reason": "Product No Longer Needed",
                                           "line_items": ["123": ["qty": 1,
                                                                  "refund_total": "8.00"]]]

        let itemRefund = LineItemRefund(itemID: "123", quantity: 1, refundTotal: "8.00", refundTax: nil)
        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", apiRefund: false, items: [itemRefund])
        let refundDict = refund.toDictionary()

        XCTAssert(NSDictionary(dictionary: expectation).isEqual(to: refundDict))
    }
}

/// Private Methods.
///
private extension RefundTests {

    /// Returns the expected dictionary for a full refund.
    ///
    func dictionaryFullRefund() -> [String: Any] {
        return ["amount": "10.00", "api_refund": true, "reason": "Product No Longer Needed"]
    }

    /// Returns the expected dictionary for a refund for single product including taxes.
    ///
    func dictionaryRefundForSingleProductIncludingTax() -> [String: Any] {
        return ["amount": "10.00",
                "reason": "Product No Longer Needed",
                "api_refund": true,
                "line_items": ["123": ["qty": 1,
                                       "refund_total": "8.00",
                                       "refund_tax": ["789": "2.00"]]]]
    }

    /// Returns the expected dictionary for a partial refund for single product including only taxes.
    ///
    func dictionaryPartialRefundForSingleProductOnlyTax() -> [String: Any] {
        return ["amount": "2.00",
                "api_refund": true,
                "line_items": ["123": ["qty": 1,
                                       "refund_tax": ["789": "2.00"]]]]
    }

    /// Returns the expected dictionary for a partial refund for single product excluding taxes.
    ///
    func dictionaryPartialRefundForSingleProductExcludingTax() -> [String: Any] {
        return ["amount": "10.00",
                "api_refund": false,
                "reason": "Product No Longer Needed",
                "line_items": ["123": ["qty": 1,
                                       "refund_total": "8.00"]]]
    }
}
