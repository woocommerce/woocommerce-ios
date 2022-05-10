import XCTest
@testable import Yosemite

final class PaymentIntent_ReceiptParametersTests: XCTestCase {
    func test_receipt_parameters_is_generated_from_intent_with_a_charge_that_contains_paymentMethod_card_details() {
        // Given
        let intent = PaymentIntent.fake().copy(amount: 100, charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])

        // When
        let receiptParameters = intent.receiptParameters()

        // Then
        XCTAssertEqual(receiptParameters?.amount, intent.amount)
        XCTAssertEqual(receiptParameters?.currency, intent.currency)

        guard let cardDetails = intent.charges.first?.paymentMethod?.cardPresentDetails else {
            return XCTFail()
        }

        XCTAssertEqual(receiptParameters?.cardDetails, cardDetails)
    }

    func test_receipt_parameters_includes_store_from_intent_metadata() {
        // Given
        let metadata = PaymentIntent.initMetadata(store: "Store Name", orderID: 134)
        let intent = PaymentIntent.fake().copy(metadata: metadata, charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])

        // Then
        XCTAssertEqual(intent.receiptParameters()?.storeName, "Store Name")
    }

    func test_receipt_parameters_includes_orderID_from_intent_metadata() {
        // Given
        let metadata = PaymentIntent.initMetadata(store: "Store Name", orderID: 1920)
        let intent = PaymentIntent.fake().copy(metadata: metadata, charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])

        // Then
        XCTAssertEqual(intent.receiptParameters()?.orderID, 1920)
    }

    func test_receiptParameters_Includes_formattedAmount_WithDecimalFormatting() {
        // Given
        let intent = PaymentIntent.fake().copy(amount: 10000, charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])

        // Then
        XCTAssertEqual(intent.receiptParameters()?.formattedAmount, "100.00")
    }
}
