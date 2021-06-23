import Foundation
import XCTest
@testable import Networking

/// Unit Tests for `CountryListMapperTests`
///
class CountryListMapperTests: XCTestCase {

    /// Verifies that the Country List is parsed correctly.
    ///
    func test_countries_are_properly_parsed() {
        guard let countries = mapCountriesResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(countries.count, 2)
        XCTAssertEqual(countries.first?.code, "PY")
        XCTAssertEqual(countries.first?.name, "Paraguay")
        XCTAssertEqual(countries.first?.states.count, 18)
        XCTAssertEqual(countries.first?.states.first, StateOfACountry(code: "PY-ASU", name: "Asunción"))
    }
}

/// Private Helpers
///
private extension CountryListMapperTests {

    /// Returns the CountryListMapperTests output upon receiving `filename` (Data Encoded)
    ///
    func mapCountries(from filename: String) -> [Country]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! CountryListMapper().map(response: response)
    }

    /// Returns the CountryListMapper output upon receiving `countries`
    ///
    func mapCountriesResponse() -> [Country]? {
        return mapCountries(from: "countries")
    }
}
