import XCTest
import Foundation
@testable import WooCommerce
@testable import Networking

/// Address+Woo Tests
///
class AddressWooTests: XCTestCase {
    func test_from_taxRate_when_tax_rate_location_is_empty_then_address_is_empty() {
        let taxRate = TaxRate.fake()

        XCTAssertTrue(Address.from(taxRate: taxRate).isEmpty)
    }

    func test_from_taxRate_when_tax_rate_has_location_then_prioritizes_array_properties() {
        // Given
        let taxRate = TaxRate.fake().copy(country: "US", state: "CA", postcode: "12345", postcodes: ["9999"], city: "Miami", cities: ["New York"])

        // When
        let address = Address.from(taxRate: taxRate)

        // Then
        XCTAssertEqual(address.state, taxRate.state)
        XCTAssertEqual(address.country, taxRate.country)
        XCTAssertEqual(address.city, taxRate.cities.first)
        XCTAssertEqual(address.postcode, taxRate.postcodes.first)
    }

    /// Older woo versions before 5.3 doesn't support arrays of postcodes and cities, use the single property then
    ///
    func test_from_taxRate_when_tax_rate_has_location_but_array_properties_are_empty_then_ressorts_to_single_properties() {
        // Given
        let taxRate = TaxRate.fake().copy(country: "US", state: "CA", postcode: "12345", postcodes: [], city: "Miami", cities: [])

        // When
        let address = Address.from(taxRate: taxRate)

        // Then
        XCTAssertEqual(address.state, taxRate.state)
        XCTAssertEqual(address.country, taxRate.country)
        XCTAssertEqual(address.city, taxRate.city)
        XCTAssertEqual(address.postcode, taxRate.postcode)
    }

    func test_resettingTaxRateComponents_erases_tax_rates_field() {
        // Given
        let taxRate = TaxRate.fake().copy(country: "US", state: "CA", postcode: "12345", postcodes: ["9999"], city: "Miami", cities: ["New York"])
        let address = Address.from(taxRate: taxRate)

        // When
        let newAddress = address.resettingTaxRateComponents()

        // Then
        XCTAssertTrue(newAddress.state.isEmpty)
        XCTAssertTrue(newAddress.country.isEmpty)
        XCTAssertTrue(newAddress.city.isEmpty)
        XCTAssertTrue(newAddress.postcode.isEmpty)
    }
}
