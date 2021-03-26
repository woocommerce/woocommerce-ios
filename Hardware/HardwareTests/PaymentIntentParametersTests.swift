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

    func test_statementDescription_replaces_expected_characters() throws {
        let params = PaymentIntentParameters(amount: 100, currency: "usd", statementDescription: "A < DESCRIPTION' longer THAN 22 Characters")

        let statementDescription = try XCTUnwrap(params.statementDescription)

        XCTAssertTrue(statementDescription.count <= 22)
        XCTAssertEqual(params.statementDescription, "A - DESCRIPTION- longe")
    }

    func test_statementDescription_leaves_strings_untouched_when_no_replacement_is_necessary() throws {
        let params = PaymentIntentParameters(amount: 100, currency: "usd", statementDescription: "A DESCRIPTION")

        let statementDescription = try XCTUnwrap(params.statementDescription)

        XCTAssertEqual(statementDescription, "A DESCRIPTION")
    }

    func test_statementDescription_trims_strings_to_22_characters() throws {
        let params = PaymentIntentParameters(amount: 100, currency: "usd", statementDescription: "A DESCRIPTION LONGER THAN 22 CHARACTERS")

        let statementDescription = try XCTUnwrap(params.statementDescription)

        XCTAssertEqual(statementDescription, "A DESCRIPTION LONGER T")
    }
}
