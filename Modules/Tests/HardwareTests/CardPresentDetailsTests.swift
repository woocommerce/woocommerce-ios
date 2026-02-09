import Testing
@testable import Hardware

/// Tests the mapping between CardPresentDetails and SCPCardPresentDetails
struct `Card Present Details Tests` {
    @Test func `card present details maps last 4`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.last4 == mockDetails.last4)
    }

    @Test func `card present details maps expiration month`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.expMonth == mockDetails.expMonth)
    }

    @Test func `card present details maps expiration year`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.expYear == mockDetails.expYear)
    }

    @Test func `card present details maps cardholder name`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.cardholderName == mockDetails.cardholderName)
    }

    @Test func `card present details maps card brand`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        let hardwareCardBrand = Hardware.CardBrand(brand: mockDetails.brand)

        #expect(details.brand == hardwareCardBrand)
    }

    @Test func `card present details maps generated card`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.generatedCard == mockDetails.generatedCard)
    }

    @Test func `card present details maps auth data`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.emvAuthData == mockDetails.emvAuthData)
    }

    @Test func `card present details maps wallet`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.wallet?.type == mockDetails.wallet?.type)
    }

    @Test func `card present details maps network`() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.network == mockDetails.network)
    }
}
