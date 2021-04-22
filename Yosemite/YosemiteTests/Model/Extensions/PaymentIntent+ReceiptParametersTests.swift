import XCTest
@testable import Yosemite

final class PaymentIntent_ReceiptParametersTests: XCTestCase {
    func test_receipt_parameters_is_generated_from_valid_intent() {
        let intent = MockPaymentIntent.mock()

        let receiptParametes = intent.receiptParameters()

        XCTAssertEqual(receiptParametes?.amount, intent.amount)
        XCTAssertEqual(receiptParametes?.currency, intent.currency)

        guard let paymentMethod = intent.charges.first?.paymentMethod,
              case .presentCard(details: let cardDetails) = paymentMethod else {
            XCTFail()
            return
        }

        XCTAssertEqual(receiptParametes?.cardDetails, cardDetails)
    }
}
