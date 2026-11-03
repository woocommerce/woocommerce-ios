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

    // MARK: - formattedPostalAddressWithPhone

    func test_formattedPostalAddressWithPhone_when_address_and_phone_exist_then_phone_is_last_line() throws {
        // Given
        let address = Self.addressWithPostalFields.copy(phone: "2125550199")
        let postalAddress = try XCTUnwrap(address.formattedPostalAddress)

        // When
        let result = address.formattedPostalAddressWithPhone

        // Then
        XCTAssertEqual(result, postalAddress + "\n2125550199")
        XCTAssertEqual(result?.components(separatedBy: "\n").last, "2125550199")
    }

    /// The country line and city/state separators depend on the device locale, so only the stable lines are pinned.
    ///
    func test_formattedPostalAddressWithPhone_when_address_and_phone_exist_then_lines_are_street_then_city_then_phone() throws {
        // Given
        let address = Self.addressWithPostalFields.copy(phone: "2125550199")

        // When
        let result = try XCTUnwrap(address.formattedPostalAddressWithPhone)

        // Then
        let lines = result.components(separatedBy: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 3)
        XCTAssertEqual(lines.first, "60 29th Street")
        XCTAssertTrue(lines[1].contains("San Francisco"))
        XCTAssertTrue(lines[1].contains("94110"))
        XCTAssertEqual(lines.last, "2125550199")
    }

    func test_formattedPostalAddressWithPhone_when_phone_is_nil_then_equals_formattedPostalAddress() {
        // Given
        let address = Self.addressWithPostalFields.copy(phone: .some(nil))

        // When
        let result = address.formattedPostalAddressWithPhone

        // Then
        XCTAssertNotNil(address.formattedPostalAddress)
        XCTAssertEqual(result, address.formattedPostalAddress)
    }

    func test_formattedPostalAddressWithPhone_when_phone_is_empty_then_equals_formattedPostalAddress() {
        // Given
        let address = Self.addressWithPostalFields.copy(phone: "")

        // When
        let result = address.formattedPostalAddressWithPhone

        // Then
        XCTAssertNotNil(address.formattedPostalAddress)
        XCTAssertEqual(result, address.formattedPostalAddress)
    }

    func test_formattedPostalAddressWithPhone_when_phone_is_only_whitespace_then_phone_is_ignored() {
        // Given
        let address = Self.addressWithPostalFields.copy(phone: "  \n ")

        // When
        let result = address.formattedPostalAddressWithPhone

        // Then
        XCTAssertNotNil(address.formattedPostalAddress)
        XCTAssertEqual(result, address.formattedPostalAddress)
    }

    func test_formattedPostalAddressWithPhone_when_phone_has_surrounding_whitespace_then_phone_is_trimmed() throws {
        // Given
        let address = Self.addressWithPostalFields.copy(phone: "  2125550199 ")
        let postalAddress = try XCTUnwrap(address.formattedPostalAddress)

        // When
        let result = address.formattedPostalAddressWithPhone

        // Then
        XCTAssertEqual(result, postalAddress + "\n2125550199")
    }

    func test_formattedPostalAddressWithPhone_when_only_phone_exists_then_returns_only_phone() {
        // Given
        let address = Address.empty.copy(phone: "2125550199")

        // When
        let result = address.formattedPostalAddressWithPhone

        // Then
        XCTAssertEqual(result, "2125550199")
    }

    func test_formattedPostalAddressWithPhone_when_address_is_empty_then_returns_nil() {
        // Given
        let address = Address.empty

        // When
        let result = address.formattedPostalAddressWithPhone

        // Then
        XCTAssertNil(result)
    }

    func test_formattedPostalAddressWithPhone_when_phone_is_only_whitespace_and_address_is_empty_then_returns_nil() {
        // Given
        let address = Address.empty.copy(phone: "   ")

        // When
        let result = address.formattedPostalAddressWithPhone

        // Then
        XCTAssertNil(result)
    }

    // MARK: - fullNameWithCompanyAddressAndPhone

    func test_fullNameWithCompanyAddressAndPhone_when_all_fields_exist_then_returns_name_company_address_and_phone_lines() throws {
        // Given
        let address = Self.addressWithPostalFields.copy(firstName: "Skylar", lastName: "Ferry", company: "Automattic", phone: "2125550199")
        let postalAddress = try XCTUnwrap(address.formattedPostalAddress)
        let nameWithCompany = address.fullNameWithCompany

        // When
        let result = address.fullNameWithCompanyAddressAndPhone

        // Then
        XCTAssertEqual(result, [nameWithCompany, postalAddress, "2125550199"].joined(separator: "\n"))
        XCTAssertEqual(result.components(separatedBy: "\n").last, "2125550199")
    }

    func test_fullNameWithCompanyAddressAndPhone_when_name_and_company_are_empty_then_has_no_leading_blank_line() throws {
        // Given
        let address = Self.addressWithPostalFields.copy(firstName: "", lastName: "", company: "", phone: "2125550199")
        let postalAddress = try XCTUnwrap(address.formattedPostalAddress)

        // When
        let result = address.fullNameWithCompanyAddressAndPhone

        // Then
        XCTAssertEqual(result, postalAddress + "\n2125550199")
        XCTAssertFalse(result.hasPrefix("\n"))
    }

    func test_fullNameWithCompanyAddressAndPhone_when_no_phone_then_equals_fullNameWithCompanyAndAddress() {
        // Given
        let address = Self.addressWithPostalFields.copy(firstName: "Skylar", lastName: "Ferry", company: "Automattic", phone: "")

        // When
        let result = address.fullNameWithCompanyAddressAndPhone

        // Then
        XCTAssertEqual(result, address.fullNameWithCompanyAndAddress)
    }

    func test_fullNameWithCompanyAddressAndPhone_when_only_phone_exists_then_returns_only_phone() {
        // Given
        let address = Address.empty.copy(phone: "2125550199")

        // When
        let result = address.fullNameWithCompanyAddressAndPhone

        // Then
        XCTAssertEqual(result, "2125550199")
    }

    func test_fullNameWithCompanyAddressAndPhone_when_name_and_phone_exist_without_postal_address_then_returns_name_and_phone() {
        // Given
        let address = Address.empty.copy(firstName: "Skylar", lastName: "Ferry", phone: "2125550199")

        // When
        let result = address.fullNameWithCompanyAddressAndPhone

        // Then
        XCTAssertEqual(result, address.fullNameWithCompany + "\n2125550199")
    }

    func test_fullNameWithCompanyAddressAndPhone_when_address_is_empty_then_returns_empty_string() {
        // Given
        let address = Address.empty

        // When
        let result = address.fullNameWithCompanyAddressAndPhone

        // Then
        XCTAssertEqual(result, "")
    }
}

private extension AddressWooTests {
    static var addressWithPostalFields: Address {
        Address.fake().copy(address1: "60 29th Street",
                            city: "San Francisco",
                            state: "CA",
                            postcode: "94110",
                            country: "US")
    }
}
