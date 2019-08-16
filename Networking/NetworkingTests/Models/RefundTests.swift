import XCTest
@testable import Networking


/// Refund Unit Tests
///
final class RefundTests: XCTestCase {

    func testFullRefund(){
        
        let dictExpected: [String: Any] = ["amount": "10.00", "reason": "Product No Longer Needed"]
        
        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", items: nil)
        let refundDict = refund.toDictionary()
        
        XCTAssert(NSDictionary(dictionary: dictExpected).isEqual(to: refundDict))
    }

    func testPartialRefundForSingleProductIncludingTax(){
        let dictExpected: [String: Any] = ["amount": "10.00",
                                           "reason": "Product No Longer Needed",
                                           "line_items": ["123": ["qty": 1,
                                                                  "refund_total": "8.00",
                                                                  "refund_tax":["789":"2.00"]]]]
        
        let itemRefund = LineItemRefund(itemID: "123", quantity: 1, refundTotal: "8.00", refundTax: [TaxRefund(taxIDLineItem: "789", amount: "2.00")])
        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", items: [itemRefund])
        let refundDict = refund.toDictionary()
        
        XCTAssert(NSDictionary(dictionary: dictExpected).isEqual(to: refundDict))
    }
    
    func testPartialRefundForSingleProductOnlyTax(){
        let dictExpected: [String: Any] = ["amount": "2.00",
                                           "line_items": ["123": ["qty": 1,
                                                                  "refund_tax":["789":"2.00"]]]]
        
        let itemRefund = LineItemRefund(itemID: "123", quantity: 1, refundTotal: nil, refundTax: [TaxRefund(taxIDLineItem: "789", amount: "2.00")])
        let refund = Refund(amount: "2.00", reason: nil, items: [itemRefund])
        let refundDict = refund.toDictionary()
        
        XCTAssert(NSDictionary(dictionary: dictExpected).isEqual(to: refundDict))
    }
    
    func testPartialRefundForSingleProductExcludingTax(){
        let dictExpected: [String: Any] = ["amount": "10.00",
                                           "reason": "Product No Longer Needed",
                                           "line_items": ["123": ["qty": 1,
                                                                  "refund_total": "8.00"]]]
        
        let itemRefund = LineItemRefund(itemID: "123", quantity: 1, refundTotal: "8.00", refundTax: nil)
        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", items: [itemRefund])
        let refundDict = refund.toDictionary()
        
        XCTAssert(NSDictionary(dictionary: dictExpected).isEqual(to: refundDict))
    }
}
