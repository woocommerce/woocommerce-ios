import XCTest
@testable import WooCommerce
@testable import Yosemite

final class EUCustomsScenarioValidatorTests: XCTestCase {
    func test_when_origin_country_is_US_and_destination_country_is_not_in_EU_new_custom_rules_then_return_false() {
        assertValidationFailsFor(origin: "US", destination: "BR")
    }

    private func assertValidationSucceedsFor(origin: String, destination: String) {
        // Given
        let originAddress = createShippingLabelAddressWith(country: origin)
        let destinationAddress = createShippingLabelAddressWith(country: destination)

        // When
        let result = EUCustomsScenarioValidator.validate(origin: originAddress, destination: destinationAddress)

        // Then
        XCTAssertTrue(result)
    }

    private func assertValidationFailsFor(origin: String, destination: String) {
        // Given
        let originAddress = createShippingLabelAddressWith(country: origin)
        let destinationAddress = createShippingLabelAddressWith(country: destination)

        // When
        let result = EUCustomsScenarioValidator.validate(origin: originAddress, destination: destinationAddress)

        // Then
        XCTAssertFalse(result)
    }

    private func createShippingLabelAddressWith(country: String) -> ShippingLabelAddress {
        ShippingLabelAddress(company: "", name: "", phone: "", country: country, state: "", address1: "", address2: "", city: "", postcode: "")
    }
}
