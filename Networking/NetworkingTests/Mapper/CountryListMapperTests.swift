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

        XCTAssertEqual(countries.count, 3)
        XCTAssertEqual(countries.first?.states.isEmpty, true)
        XCTAssertEqual(countries[1].code, "PY")
        XCTAssertEqual(countries[1].name, "Paraguay")
        XCTAssertEqual(countries[1].states.count, 18)
        XCTAssertEqual(countries[1].states.first, StateOfACountry(code: "PY-ASU", name: "Asunción"))
    }

    func test_countries_are_properly_parsed_if_the_response_has_no_data_envelope() {
        guard let countries = mapCountriesResponseWithoutDataEnvelope() else {
            XCTFail()
            return
        }

        XCTAssertEqual(countries.count, 3)
        XCTAssertEqual(countries.first?.states.isEmpty, true)
        XCTAssertEqual(countries[1].code, "PY")
        XCTAssertEqual(countries[1].name, "Paraguay")
        XCTAssertEqual(countries[1].states.count, 18)
        XCTAssertEqual(countries[1].states.first, StateOfACountry(code: "PY-ASU", name: "Asunción"))
    }
}

/// Private Helpers
///
private extension CountryListMapperTests {

    /// Returns the CountryListMapperTests output upon receiving `filename` (Data Encoded)
    ///
    func mapCountries(siteID: Int64, from filename: String) -> [Country]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! CountryListMapper(siteID: siteID).map(response: response)
    }

    /// Returns the [Country] output upon receiving `countries`
    ///
    func mapCountriesResponse() -> [Country]? {
        return mapCountries(siteID: 123, from: "countries")
    }

    /// Returns the [Country] output upon receiving `countries-without-data`
    ///
    func mapCountriesResponseWithoutDataEnvelope() -> [Country]? {
        return mapCountries(siteID: -1, from: "countries-without-data")
    }
}
