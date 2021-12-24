import XCTest
@testable import Hardware

/// Tests the mapping between CardPresentDetails and SCPCardPresentDetails
final class CardPresentDetailsTests: XCTestCase {
    func test_card_present_details_maps_last_4() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        XCTAssertEqual(details.last4, mockDetails.last4)
    }

    func test_card_present_details_maps_expiration_month() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        XCTAssertEqual(details.expMonth, mockDetails.expMonth)
    }

    func test_card_present_details_maps_expiration_year() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        XCTAssertEqual(details.expYear, mockDetails.expYear)
    }

    func test_card_present_details_maps_cardholder_name() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        XCTAssertEqual(details.cardholderName, mockDetails.cardholderName)
    }

    func test_card_present_details_maps_card_brand() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        let hardwareCardBrand = Hardware.CardBrand(brand: mockDetails.brand)

        XCTAssertEqual(details.brand, hardwareCardBrand)
    }

    func test_card_present_details_maps_fingerprint() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        XCTAssertEqual(details.fingerprint, mockDetails.fingerprint)
    }

    func test_card_present_details_maps_generated_card() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        XCTAssertEqual(details.generatedCard, mockDetails.generatedCard)
    }

    func test_card_present_details_maps_auth_data() {
        let mockDetails = MockStripeCardPresentDetails.mock()
        let details = CardPresentTransactionDetails(details: mockDetails)

        XCTAssertEqual(details.emvAuthData, mockDetails.emvAuthData)
    }
}
