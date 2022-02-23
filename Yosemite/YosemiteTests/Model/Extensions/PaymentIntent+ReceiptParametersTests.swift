import XCTest
@testable import Yosemite

final class PaymentIntent_ReceiptParametersTests: XCTestCase {
    func test_receipt_parameters_is_generated_from_valid_intent() {
        let intent = MockPaymentIntent.mock()

        let receiptParameters = intent.receiptParameters()

        XCTAssertEqual(receiptParameters?.amount, intent.amount)
        XCTAssertEqual(receiptParameters?.currency, intent.currency)

        guard let cardDetails = self.charges.first?.paymentMethod?.cardPresentDetails else {
            XCTFail()
            return
        }

        XCTAssertEqual(receiptParameters?.cardDetails, cardDetails)
    }

    func test_receipt_parameters_includes_store_from_intent_metadata() {
        let intent = MockPaymentIntent.mock()

        XCTAssertEqual(intent.receiptParameters()?.storeName, "Store Name")
    }

    func test_receipt_parameters_includes_orderID_from_intent_metadata() {
        let intent = MockPaymentIntent.mock()

        XCTAssertEqual(intent.receiptParameters()?.orderID, 1920)
    }

    func test_receiptParameters_Includes_formattedAmount_WithDecimalFormatting() {
        let intent = MockPaymentIntent.mock()

        XCTAssertEqual(intent.receiptParameters()?.formattedAmount, "100.00")
    }
}
