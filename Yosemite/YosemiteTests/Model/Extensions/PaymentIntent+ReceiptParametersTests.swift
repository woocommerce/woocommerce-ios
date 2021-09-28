import XCTest
@testable import Yosemite

final class PaymentIntent_ReceiptParametersTests: XCTestCase {
    func test_receipt_parameters_is_generated_from_valid_intent() {
        let intent = MockPaymentIntent.mock()

        let receiptParameters = intent.receiptParameters()

        XCTAssertEqual(receiptParameters?.amount, intent.amount)
        XCTAssertEqual(receiptParameters?.currency, intent.currency)

        guard let paymentMethod = intent.charges.first?.paymentMethod,
              case .presentCard(details: let cardDetails) = paymentMethod else {
            XCTFail()
            return
        }

        XCTAssertEqual(receiptParameters?.cardDetails, cardDetails)
    }
}
