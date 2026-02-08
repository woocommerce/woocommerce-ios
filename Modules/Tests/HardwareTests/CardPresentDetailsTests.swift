import Testing
@testable import Hardware

/// Tests the mapping between CardPresentDetails and SCPCardPresentDetails
@Suite("Card Present Details Tests")
struct CardPresentDetailsTests {
    @Test func test_card_present_details_maps_last_4() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.last4 == mockDetails.last4)
    }

    @Test func test_card_present_details_maps_expiration_month() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.expMonth == mockDetails.expMonth)
    }

    @Test func test_card_present_details_maps_expiration_year() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.expYear == mockDetails.expYear)
    }

    @Test func test_card_present_details_maps_cardholder_name() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.cardholderName == mockDetails.cardholderName)
    }

    @Test func test_card_present_details_maps_card_brand() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        let hardwareCardBrand = Hardware.CardBrand(brand: mockDetails.brand)

        #expect(details.brand == hardwareCardBrand)
    }

    @Test func test_card_present_details_maps_generated_card() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.generatedCard == mockDetails.generatedCard)
    }

    @Test func test_card_present_details_maps_auth_data() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.emvAuthData == mockDetails.emvAuthData)
    }

    @Test func test_card_present_details_maps_wallet() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.wallet?.type == mockDetails.wallet?.type)
    }

    @Test func test_card_present_details_maps_network() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        #expect(details.network == mockDetails.network)
    }
}
