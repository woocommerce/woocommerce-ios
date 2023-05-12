import XCTest
@testable import WooCommerce
@testable import Yosemite

final class EUCustomsScenarioValidatorTests: XCTestCase {
    private func assertValidationSucceedsFor(origin: String, destination: String) {
        // Given
        let originAddress = createShippingLabelAddressWith(country: origin)
        let destinationAddress = createShippingLabelAddressWith(country: destination)

        // When
        let result = EUCustomsScenarioValidator.validate(origin: originAddress, destination: destinationAddress)

        // Then
        XCTAssertTrue(result)
    }

    private func createShippingLabelAddressWith(country: String) -> ShippingLabelAddress {
        ShippingLabelAddress(company: "", name: "", phone: "", country: country, state: "", address1: "", address2: "", city: "", postcode: "")
    }
}
