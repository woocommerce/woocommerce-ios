import Foundation
import XCTest
@testable import Networking
@testable import NetworkingCore

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

    func test_map_when_country_names_contain_HTML_entities_then_names_are_decoded() throws {
        // Given
        let response = Data("""
        [
            {"code": "CW", "name": "Cura&ccedil;ao", "states": []},
            {"code": "BL", "name": "Saint Barth&eacute;lemy", "states": []},
            {"code": "ST", "name": "S&atilde;o Tom&eacute; and Pr&iacute;ncipe", "states": []},
            {"code": "US", "name": "United States (US)", "states": []},
            {"code": "XX", "name": "Trinidad & Tobago", "states": []}
        ]
        """.utf8)

        // When
        let countries = try CountryListMapper().map(response: response)

        // Then
        XCTAssertEqual(countries.map(\.name), [
            "Curaçao",
            "Saint Barthélemy",
            "São Tomé and Príncipe",
            "United States (US)",
            "Trinidad & Tobago"
        ])
    }

    func test_map_when_state_names_contain_HTML_entities_then_names_are_decoded() throws {
        // Given
        let response = Data("""
        [
            {"code": "AR", "name": "Argentina", "states": [{"code": "X", "name": "C&oacute;rdoba"}]},
            {"code": "CO", "name": "Colombia", "states": [{"code": "CO-SAP", "name": "San Andrés & Providencia"}]}
        ]
        """.utf8)

        // When
        let countries = try CountryListMapper().map(response: response)

        // Then
        XCTAssertEqual(countries.flatMap(\.states).map(\.name), ["Córdoba", "San Andrés & Providencia"])
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

    /// Returns the [Country] output upon receiving `countries`
    ///
    func mapCountriesResponse() -> [Country]? {
        return mapCountries(from: "country-list")
    }

    /// Returns the [Country] output upon receiving `countries-without-data`
    ///
    func mapCountriesResponseWithoutDataEnvelope() -> [Country]? {
        return mapCountries(from: "countries-without-data")
    }
}
