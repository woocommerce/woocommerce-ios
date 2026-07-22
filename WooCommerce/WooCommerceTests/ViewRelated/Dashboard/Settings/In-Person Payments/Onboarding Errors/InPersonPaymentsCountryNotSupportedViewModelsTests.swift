import Foundation
import Testing
@testable import WooCommerce
import enum WooFoundation.CountryCode

/// Tests for the view models backing the country-not-supported onboarding error views.
///
struct InPersonPaymentsCountryNotSupportedViewModelsTests {

    @Test func countryNotSupported_title_when_the_country_is_known_then_includes_the_localized_country_name() async throws {
        // Given
        let sut = InPersonPaymentsCountryNotSupportedViewModel(countryCode: .ES, analyticReason: "")
        let expectedCountryName = try #require(Locale.current.localizedString(forRegionCode: "ES"))

        // Then
        #expect(sut.title.contains(expectedCountryName))
    }

    @Test func countryNotSupported_title_when_the_country_is_unknown_then_falls_back_to_the_generic_title() async throws {
        // Given
        let sut = InPersonPaymentsCountryNotSupportedViewModel(countryCode: .unknown, analyticReason: "")

        // Then
        #expect(sut.title.contains("your country"))
        #expect(!sut.title.contains("%1$@"))
    }

    @Test func countryNotSupportedStripe_title_when_the_country_is_known_then_includes_the_localized_country_name() async throws {
        // Given
        let sut = InPersonPaymentsCountryNotSupportedStripeViewModel(countryCode: .ES, analyticReason: "")
        let expectedCountryName = try #require(Locale.current.localizedString(forRegionCode: "ES"))

        // Then
        #expect(sut.title.contains(expectedCountryName))
        #expect(sut.title.contains("Stripe"))
    }

    @Test func countryNotSupportedStripe_title_when_the_country_is_unknown_then_falls_back_to_the_generic_title() async throws {
        // Given
        let sut = InPersonPaymentsCountryNotSupportedStripeViewModel(countryCode: .unknown, analyticReason: "")

        // Then
        #expect(sut.title.contains("your country"))
        #expect(!sut.title.contains("%1$@"))
    }
}
