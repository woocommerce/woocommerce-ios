import XCTest
@testable import Hardware

final class PaymentIntentParametersTests: XCTestCase {
    func test_validEmail_is_saved() {
        let params = PaymentIntentParameters(amount: 100, currency: "usd", receiptEmail: "validemail@validdomain.us")

        XCTAssertNotNil(params.receiptEmail)
    }

    func test_not_validEmail_is_ignored() {
        let params = PaymentIntentParameters(amount: 100, currency: "usd", receiptEmail: "woocommerce")

        XCTAssertNil(params.receiptEmail)
    }

    func test_currency_is_lowercased() {
        let params = PaymentIntentParameters(amount: 100, currency: "USD")

        XCTAssertEqual(params.currency, "usd")
    }
}
