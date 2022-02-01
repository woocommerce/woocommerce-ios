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

    func test_parameters_do_not_validate_if_currency_code_is_not_supported() {
        let params = PaymentIntentParameters(amount: 100, currency: "cesar")

        XCTAssertNil(params.toStripe())
    }

    func test_parameters_do_not_validate_if_currency_code_is_empty() {
        let params = PaymentIntentParameters(amount: 100, currency: "")

        XCTAssertNil(params.toStripe())
    }

    func test_amount_is_converted_to_smallest_unit_before_being_passed_to_stripe() throws {
        let amount = Decimal(120.10)
        let expectation = UInt(12010)

        let params = PaymentIntentParameters(amount: amount, currency: "usd")
        let stripeParams = try XCTUnwrap(params.toStripe())

        XCTAssertEqual(expectation, stripeParams.amount)
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

    func test_statementDescription_is_passed_as_nil_when_empty() throws {
        let params = PaymentIntentParameters(amount: 100, currency: "usd", statementDescription: "")

        let stripeParameters = params.toStripe()

        XCTAssertNil(stripeParameters?.statementDescriptor)
    }

    func test_customer_id_is_passed_to_stripe() {
        let customerID = "customer_id"
        let params = PaymentIntentParameters(amount: 100, currency: "usd", statementDescription: "A DESCRIPTION", customerID: customerID)

        let stripeParameters = params.toStripe()

        XCTAssertEqual(stripeParameters?.customer, customerID)
    }
}
