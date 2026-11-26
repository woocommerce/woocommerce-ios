import Testing
import enum WooFoundation.CountryCode
import struct Yosemite.CardPresentPaymentsConfiguration
@testable import WooCommerce

@MainActor
struct TapToPayEducationStepsFactoryTests {
    @Test func steps_when_country_is_US_then_returns_three_steps_without_PIN() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .US)

        // When
        let steps = TapToPayEducationStepsFactory.steps(configuration: configuration)

        // Then
        #expect(steps.count == 3)
        #expect(!steps.map(\.imageName).contains("tap-to-pay-education-pin-gb"))
        #expect(steps.allSatisfy { $0.limit == nil })
    }

    @Test(arguments: [CountryCode.GB, .FI, .IE, .LU, .NL, .NZ, .SG])
    func steps_when_country_can_request_a_PIN_then_includes_PIN_and_fallback_steps(countryCode: CountryCode) {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: countryCode)

        // When
        let steps = TapToPayEducationStepsFactory.steps(configuration: configuration)

        // Then
        #expect(steps.count == 5)
        #expect(steps.map(\.imageName).suffix(2) == ["tap-to-pay-education-pin-gb", "tap-to-pay-education-fallback-payment-method-gb"])
    }

    @Test(arguments: [CountryCode.GB, .FI, .IE, .LU, .NL, .NZ])
    func steps_when_country_has_a_contactless_limit_then_intro_step_shows_the_limit(countryCode: CountryCode) {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: countryCode)

        // When
        let steps = TapToPayEducationStepsFactory.steps(configuration: configuration)

        // Then
        #expect(steps.first?.limit != nil)
    }

    @Test func steps_when_country_has_no_contactless_limit_then_intro_step_has_no_limit() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .SG)

        // When
        let steps = TapToPayEducationStepsFactory.steps(configuration: configuration)

        // Then
        #expect(steps.first?.limit == nil)
    }
}
