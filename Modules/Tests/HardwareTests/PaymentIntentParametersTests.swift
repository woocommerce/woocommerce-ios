import Foundation
import Testing
@testable import Hardware

struct `Payment Intent Parameters Tests` {
    @Test func `validEmail is saved`() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             receiptEmail: "validemail@validdomain.us",
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.receiptEmail != nil)
    }

    @Test func `not validEmail is ignored`() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             receiptEmail: "woocommerce",
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.receiptEmail == nil)
    }

    @Test func `currency is lowercased`() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "USD",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.currency == "usd")
    }

    @Test func `parameters do not validate if currency code is not supported`() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "cesar",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.toStripe() == nil)
    }

    @Test func `parameters do not validate if currency code is empty`() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [.cardPresent])

        #expect(params.toStripe() == nil)
    }

    @Test func `parameters do not validate if payment methods is empty`() {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             paymentMethodTypes: [])

        #expect(params.toStripe() == nil)
    }

    @Test func `amount is converted to smallest unit before being passed to stripe`() throws {
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

    @Test func `statementDescription replaces expected characters`() throws {
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

    @Test func `statementDescription leaves strings untouched when no replacement is necessary`() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: "A DESCRIPTION",
                                             paymentMethodTypes: [.cardPresent])

        let statementDescription = try #require(params.statementDescription)

        #expect(statementDescription == "A DESCRIPTION")
    }

    @Test func `statementDescription trims strings to 22 characters`() throws {
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

    @Test func `statementDescription is passed as nil when empty`() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: "",
                                             paymentMethodTypes: [.cardPresent])

        let stripeParameters = params.toStripe()

        #expect(stripeParameters?.statementDescriptor == nil)
    }

    @Test func `statementDescription is passed as nil when nil`() throws {
        let params = PaymentIntentParameters(amount: 100,
                                             currency: "usd",
                                             stripeSmallestCurrencyUnitMultiplier: 100,
                                             statementDescription: nil,
                                             paymentMethodTypes: [.cardPresent])

        let stripeParameters = params.toStripe()

        #expect(stripeParameters?.statementDescriptor == nil)
    }

    @Test func `cardReaderMetadata is passed to paymentIntent when sent toStripe then stripeParameters contains cardReaderMetadata`() {
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

    @Test func `cardReaderMetadata is nil when sent toStripe then stripeParameters does not contain cardReaderMetadata`() {
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
private extension `Payment Intent Parameters Tests` {
    func createPaymentIntentParameters(withMetaKeys: [String: String]? = nil) -> PaymentIntentParameters {
        PaymentIntentParameters(amount: 100,
                                currency: "usd",
                                stripeSmallestCurrencyUnitMultiplier: 100,
                                paymentMethodTypes: [.cardPresent],
                                metadata: withMetaKeys)
    }
}
