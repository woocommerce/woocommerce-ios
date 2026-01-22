import XCTest
@testable import WooCommerce

final class POSPromoOnPhonesCampaignTests: XCTestCase {

    func test_configuration_has_correct_source() {
        // Given
        let sut = POSPromoOnPhonesCampaign()

        // When
        let configuration = sut.configuration

        // Then
        XCTAssertEqual(configuration.source, .myStore)
    }

    func test_configuration_has_correct_campaign() {
        // Given
        let sut = POSPromoOnPhonesCampaign()

        // When
        let configuration = sut.configuration

        // Then
        XCTAssertEqual(configuration.campaign, .posPromoOnPhones)
    }

    func test_configuration_has_non_empty_title() {
        // Given
        let sut = POSPromoOnPhonesCampaign()

        // When
        let configuration = sut.configuration

        // Then
        XCTAssertFalse(configuration.title.isEmpty)
    }

    func test_configuration_has_non_empty_message() {
        // Given
        let sut = POSPromoOnPhonesCampaign()

        // When
        let configuration = sut.configuration

        // Then
        XCTAssertFalse(configuration.message.isEmpty)
    }

    func test_configuration_has_non_empty_button_title() {
        // Given
        let sut = POSPromoOnPhonesCampaign()

        // When
        let configuration = sut.configuration

        // Then
        XCTAssertNotNil(configuration.buttonTitle)
        XCTAssertFalse(configuration.buttonTitle?.isEmpty ?? true)
    }

    func test_ctaURLString_matches_posLearnMore() {
        // Then
        XCTAssertEqual(POSPromoOnPhonesCampaign.ctaURLString, WooConstants.URLs.posLearnMore.rawValue)
    }

    func test_configuration_does_not_show_dividers() {
        // Given
        let sut = POSPromoOnPhonesCampaign()

        // When
        let configuration = sut.configuration

        // Then
        XCTAssertFalse(configuration.showDividers)
    }

    func test_configuration_does_not_show_dismiss_confirmation() {
        // Given
        let sut = POSPromoOnPhonesCampaign()

        // When
        let configuration = sut.configuration

        // Then
        XCTAssertFalse(configuration.showDismissConfirmation)
    }
}
