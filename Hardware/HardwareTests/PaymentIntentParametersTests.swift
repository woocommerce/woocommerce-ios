import XCTest
@testable import Hardware

final class PaymentIntentParametersTests: XCTestCase {
    func test_validEmail_is_saved() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             receiptEmail: "validemail@validdomain.us",
                                             paymentMethodTypes: ["card_present"])

        XCTAssertNotNil(params.receiptEmail)
    }

    func test_not_validEmail_is_ignored() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             receiptEmail: "woocommerce",
                                             paymentMethodTypes: ["card_present"])

        XCTAssertNil(params.receiptEmail)
    }

    func test_currency_is_lowercased() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "USD",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: ["card_present"])

        XCTAssertEqual(params.currency, "usd")
    }

    func test_parameters_do_not_validate_if_currency_code_is_not_supported() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "cesar",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: ["card_present"])

        XCTAssertNil(params.toStripe())
    }

    func test_parameters_do_not_validate_if_currency_code_is_empty() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: ["card_present"])

        XCTAssertNil(params.toStripe())
    }

    func test_parameters_do_not_validate_if_payment_methods_is_empty() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [])

        XCTAssertNil(params.toStripe())
    }

    func test_amount_is_converted_to_smallest_unit_before_being_passed_to_stripe() throws {
        let stripeSmallestCurrencyUnitMultiplier: Decimal = 200
        let amount = Decimal(120.10)
        let amountInSmallestUnit = amount * stripeSmallestCurrencyUnitMultiplier
        let expectation = NSDecimalNumber(decimal: amountInSmallestUnit).uintValue

        let params = PaymentIntentParameters(amount: amount,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: stripeSmallestCurrencyUnitMultiplier,
                                             paymentMethodTypes: ["card_present"])
        let stripeParams = try XCTUnwrap(params.toStripe())

        XCTAssertEqual(expectation, stripeParams.amount)
    }

    func test_statementDescription_replaces_expected_characters() throws {
        let params = PaymentIntentParameters(
            amount: 100,
            currency: "usd",
            stripeSmallestCurrencyUnitMultiplier: 100,
            statementDescription: "A < DESCRIPTION' longer THAN 22 Characters",
            paymentMethodTypes: ["card_present"]
        )

        let statementDescription = try XCTUnwrap(params.statementDescription)

        XCTAssertTrue(statementDescription.count <= 22)
        XCTAssertEqual(params.statementDescription, "A - DESCRIPTION- longe")
    }

    func test_statementDescription_leaves_strings_untouched_when_no_replacement_is_necessary() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: "A DESCRIPTION",
                                             paymentMethodTypes: ["card_present"])

        let statementDescription = try XCTUnwrap(params.statementDescription)

        XCTAssertEqual(statementDescription, "A DESCRIPTION")
    }

    func test_statementDescription_trims_strings_to_22_characters() throws {
        let params = PaymentIntentParameters(
            amount: 100,
            currency: "usd",
            stripeSmallestCurrencyUnitMultiplier: 100,
            statementDescription: "A DESCRIPTION LONGER THAN 22 CHARACTERS",
            paymentMethodTypes: ["card_present"]
        )

        let statementDescription = try XCTUnwrap(params.statementDescription)

        XCTAssertEqual(statementDescription, "A DESCRIPTION LONGER T")
    }

    func test_statementDescription_is_passed_as_nil_when_empty() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: "",
                                             paymentMethodTypes: ["card_present"])

        let stripeParameters = params.toStripe()

        XCTAssertNil(stripeParameters?.statementDescriptor)
    }

    func test_statementDescription_is_passed_as_nil_when_nil() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: nil,
                                             paymentMethodTypes: ["card_present"])

        let stripeParameters = params.toStripe()

        XCTAssertNil(stripeParameters?.statementDescriptor)
    }

    func test_cardReaderMetadata_is_passed_to_paymentIntent_when_sent_toStripe_then_stripeParameters_contains_cardReaderMetadata() {
        // Given
        let expectedMetaKeys = ["reader_ID": "", "reader_model": "", "platform": ""]
        let readerID = "somereaderID"
        let readerModel = "someModel"
        let platform = "somePlatform"

        let sut = createPaymentIntentParameters(withMetaKeys: expectedMetaKeys)
        let cardReaderMeta = CardReaderMetadata(readerIDMetadataKey: readerID, readerModelMetadataKey: readerModel, platformMetadataKey: platform)

        // When
        let stripeParameters = sut.toStripe(with: cardReaderMeta)

        // Then
        XCTAssertEqual(stripeParameters?.metadata?["reader_ID"], readerID)
        XCTAssertEqual(stripeParameters?.metadata?["reader_model"], readerModel)
        XCTAssertEqual(stripeParameters?.metadata?["platform"], platform)
    }

    func test_cardReaderMetadata_is_nil_when_sent_toStripe_then_stripeParameters_does_not_contain_cardReaderMetadata() {
        // Given
        let sut = createPaymentIntentParameters()

        // When
        let stripeParameters = sut.toStripe()

        // Then
        XCTAssertNil(stripeParameters?.metadata?["reader_ID"])
        XCTAssertNil(stripeParameters?.metadata?["reader_model"])
        XCTAssertNil(stripeParameters?.metadata?["platform"])
    }
}

/// Test helpers
///
private extension PaymentIntentParametersTests {
    func createPaymentIntentParameters(withMetaKeys: [String: String]? = nil) -> PaymentIntentParameters {
        PaymentIntentParameters(amount: 100,
                                currency: "usd",
                                stripeSmallestCurrencyUnitMultiplier: 100,
                                paymentMethodTypes: ["card_present"],
                                metadata: withMetaKeys)
    }
}
