import Foundation
import XCTest
@testable import Networking

/// Unit Tests for `WooCountryListMapperTests`
///
class WooCountryListMapperTests: XCTestCase {

    /// Verifies that the WooCountry List is parsed correctly.
    ///
    func test_countries_are_properly_parsed() {
        guard let countries = mapCountriesResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(countries.count, 3)
        XCTAssertEqual(countries.first?.states.isEmpty, true)
        XCTAssertEqual(countries[1].code, "PY")
        XCTAssertEqual(countries[1].name, "Paraguay")
        XCTAssertEqual(countries[1].states.count, 18)
        XCTAssertEqual(countries[1].states.first, StateOfAWooCountry(code: "PY-ASU", name: "Asunción"))
    }
}

/// Private Helpers
///
private extension WooCountryListMapperTests {

    /// Returns the CountryListMapperTests output upon receiving `filename` (Data Encoded)
    ///
    func mapCountries(from filename: String) -> [WooCountry]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! WooCountryListMapper().map(response: response)
    }

    /// Returns the CountryListMapper output upon receiving `countries`
    ///
    func mapCountriesResponse() -> [WooCountry]? {
        return mapCountries(from: "countries")
    }
}
