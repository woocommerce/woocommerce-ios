import Foundation
import Testing
@testable import Hardware

@Suite("Payment Intent Parameters Tests")
struct PaymentIntentParametersTests {
    @Test func test_validEmail_is_saved() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             receiptEmail: "validemail@validdomain.us",
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.receiptEmail != nil)
    }

    @Test func test_not_validEmail_is_ignored() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             receiptEmail: "woocommerce",
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.receiptEmail == nil)
    }

    @Test func test_currency_is_lowercased() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "USD",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.currency == "usd")
    }

    @Test func test_parameters_do_not_validate_if_currency_code_is_not_supported() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "cesar",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.toStripe() == nil)
    }

    @Test func test_parameters_do_not_validate_if_currency_code_is_empty() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.toStripe() == nil)
    }

    @Test func test_parameters_do_not_validate_if_payment_methods_is_empty() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [])

        #expect(params.toStripe() == nil)
    }

    @Test func test_amount_is_converted_to_smallest_unit_before_being_passed_to_stripe() throws {
        let stripeSmallestCurrencyUnitMultiplier: Decimal = 200
        let amount = Decimal(120.10)
        let amountInSmallestUnit = amount * stripeSmallestCurrencyUnitMultiplier
        let expectation = NSDecimalNumber(decimal: amountInSmallestUnit).uintValue

        let params = PaymentIntentParameters(amount: amount,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: stripeSmallestCurrencyUnitMultiplier,
                                             paymentMethodTypes: [.cardPresent])
        let stripeParams = try #require(params.toStripe())

        #expect(expectation == stripeParams.amount)
    }

    @Test func test_statementDescription_replaces_expected_characters() throws {
        let params = PaymentIntentParameters(
            amount: 100,
            currency: "usd",
            stripeSmallestCurrencyUnitMultiplier: 100,
            statementDescription: "A < DESCRIPTION' longer THAN 22 Characters",
            paymentMethodTypes: [.cardPresent]
        )

        let statementDescription = try #require(params.statementDescription)

        #expect(statementDescription.count <= 22)
        #expect(params.statementDescription == "A - DESCRIPTION- longe")
    }

    @Test func test_statementDescription_leaves_strings_untouched_when_no_replacement_is_necessary() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: "A DESCRIPTION",
                                             paymentMethodTypes: [.cardPresent])

        let statementDescription = try #require(params.statementDescription)

        #expect(statementDescription == "A DESCRIPTION")
    }

    @Test func test_statementDescription_trims_strings_to_22_characters() throws {
        let params = PaymentIntentParameters(
            amount: 100,
            currency: "usd",
            stripeSmallestCurrencyUnitMultiplier: 100,
            statementDescription: "A DESCRIPTION LONGER THAN 22 CHARACTERS",
            paymentMethodTypes: [.cardPresent]
        )

        let statementDescription = try #require(params.statementDescription)

        #expect(statementDescription == "A DESCRIPTION LONGER T")
    }

    @Test func test_statementDescription_is_passed_as_nil_when_empty() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: "",
                                             paymentMethodTypes: [.cardPresent])

        let stripeParameters = params.toStripe()

        #expect(stripeParameters?.statementDescriptor == nil)
    }

    @Test func test_statementDescription_is_passed_as_nil_when_nil() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: nil,
                                             paymentMethodTypes: [.cardPresent])

        let stripeParameters = params.toStripe()

        #expect(stripeParameters?.statementDescriptor == nil)
    }

    @Test func test_cardReaderMetadata_is_passed_to_paymentIntent_when_sent_toStripe_then_stripeParameters_contains_cardReaderMetadata() {
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
        #expect(stripeParameters?.metadata?["reader_ID"] == readerID)
        #expect(stripeParameters?.metadata?["reader_model"] == readerModel)
        #expect(stripeParameters?.metadata?["platform"] == platform)
    }

    @Test func test_cardReaderMetadata_is_nil_when_sent_toStripe_then_stripeParameters_does_not_contain_cardReaderMetadata() {
        // Given
        let sut = createPaymentIntentParameters()

        // When
        let stripeParameters = sut.toStripe()

        // Then
        #expect(stripeParameters?.metadata?["reader_ID"] == nil)
        #expect(stripeParameters?.metadata?["reader_model"] == nil)
        #expect(stripeParameters?.metadata?["platform"] == nil)
    }
}

/// Test helpers
private extension PaymentIntentParametersTests {
    func createPaymentIntentParameters(withMetaKeys: [String: String]? = nil) -> PaymentIntentParameters {
        PaymentIntentParameters(amount: 100,
                                currency: "usd",
                                stripeSmallestCurrencyUnitMultiplier: 100,
                                paymentMethodTypes: [.cardPresent],
                                metadata: withMetaKeys)
    }
}
