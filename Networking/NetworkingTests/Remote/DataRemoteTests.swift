import XCTest
@testable import Networking


/// DataRemote Unit Tests
///
class DataRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    func test_loadCountries_returns_countries_on_success() throws {
        // Given
        let remote = DataRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "data/countries", filename: "countries")

        // When
        let result: Result<[Country], Error> = waitFor { promise in
            remote.loadCountries(siteID: self.sampleSiteID) { (result) in
                promise(result)
            }
        }

        // Then
        let countries = try XCTUnwrap(result.get())
        XCTAssertEqual(countries.count, 3)
        XCTAssertEqual(countries[1].code, "PY")
        XCTAssertEqual(countries[1].name, "Paraguay")
        XCTAssertEqual(countries[1].states.count, 18)
        XCTAssertEqual(countries[1].states.first, StateOfACountry(code: "PY-ASU", name: "Asunción"))
    }

    func test_loadCountries_returns_error_on_failure() throws {
        // Given
        let remote = DataRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "data/countries", filename: "generic_error")

        // When
        let result: Result<[Country], Error> = waitFor { promise in
            remote.loadCountries(siteID: self.sampleSiteID) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }
}
