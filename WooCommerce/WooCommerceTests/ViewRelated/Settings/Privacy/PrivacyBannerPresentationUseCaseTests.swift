import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

final class PrivacyBannerPresentationUseCaseTests: XCTestCase {

    func test_show_banner_is_true_when_conditions_are_met() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When & Then
        for euCode in Country.GDPRCountryCodes {
            let useCase = PrivacyBannerPresentationUseCase(countryCode: euCode, defaults: defaults)
            XCTAssertTrue(useCase.shouldShowPrivacyBanner())
        }
    }

    func test_show_banner_is_false_when_country_is_outside_of_EU_and_choices_have_not_been_saved() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = false

        // When
        let useCase = PrivacyBannerPresentationUseCase(countryCode: "PE", defaults: defaults)

        // Then
        XCTAssertFalse(useCase.shouldShowPrivacyBanner())
    }

    func test_show_banner_is_false_when_country_is_inside_of_EU_and_choices_have_been_saved() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = true

        // When
        let useCase = PrivacyBannerPresentationUseCase(countryCode: "ES", defaults: defaults)

        // Then
        XCTAssertFalse(useCase.shouldShowPrivacyBanner())
    }
}
