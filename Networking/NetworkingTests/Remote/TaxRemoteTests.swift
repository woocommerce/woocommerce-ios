import XCTest

@testable import Networking

final class TaxRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load all tax classes tests

    /// Verifies that loadAllTaxClasses properly parses the `taxes-classes` sample response.
    ///
    func test_load_all_tax_classes_properly_returns_parsed_data() async throws {
        // Given
        let remote = TaxRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")

        // When
        let taxClasses = try await remote.loadAllTaxClasses(for: sampleSiteID)

        // Then
        XCTAssertEqual(taxClasses.count, 3)

        // Validates on Tax Class with slug "standard"
        let expectedSlug = "standard"
        guard let expectedTaxClass = taxClasses.first(where: { $0.slug == expectedSlug }) else {
            XCTFail("Tax Class with slug \(expectedSlug) should exist")
            return
        }
        XCTAssertEqual(expectedTaxClass.siteID, sampleSiteID)
        XCTAssertEqual(expectedTaxClass.name, "Standard Rate")
    }

    /// Verifies that loadAllTaxClasses properly relays Networking Layer errors.
    ///
    func test_load_all_tax_classes_properly_relays_networking_errors() async {
        // Given
        let remote = TaxRemote(network: network)

        // When
        do {
            _ = try await remote.loadAllTaxClasses(for: sampleSiteID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertNotNil(error)
        }
    }

    func test_retrieveTaxRates_then_returns_parsed_data() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "taxes", filename: "taxes")

        let remote = TaxRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.retrieveTaxRates(siteID: self.sampleSiteID, pageNumber: 1, pageSize: 25) { result in
                promise(result)
            }
        }
        let rates = try XCTUnwrap(result.get())

        // Then
        XCTAssertEqual(rates.count, 3)
        XCTAssertEqual(rates.first?.id, 72)
        XCTAssertEqual(rates.first?.country, "US")
        XCTAssertEqual(rates.first?.state, "AL")
        XCTAssertEqual(rates.first?.postcode, "35041")
        XCTAssertEqual(rates.first?.city, "Cardiff")
        XCTAssertEqual(rates.first?.postcodes, ["35014", "35036", "35041"])
        XCTAssertEqual(rates.first?.rate, "4.0000")
        XCTAssertEqual(rates.first?.name, "State Tax")
        XCTAssertEqual(rates.first?.priority, 0)
        XCTAssertEqual(rates.first?.compound, false)
        XCTAssertEqual(rates.first?.shipping, false)
        XCTAssertEqual(rates.first?.order, 1)
        XCTAssertEqual(rates.first?.taxRateClass, "standard")
    }

    func test_retrieveTaxRates_then_relays_networking_errors() throws {
        // Given
        let remote = TaxRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "taxes", error: error)

        // When
        let result = waitFor { promise in
            remote.retrieveTaxRates(siteID: self.sampleSiteID, pageNumber: 1, pageSize: 25) { result in
                promise(result)
            }
        }
        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 403))
    }

    func test_retrieveTaxRate_then_returns_parsed_data() throws {
        // Given
        let taxRateID: Int64 = 1
        network.simulateResponse(requestUrlSuffix: "taxes/\(taxRateID)", filename: "tax")

        let remote = TaxRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.retrieveTaxRate(siteID: self.sampleSiteID, taxRateID: taxRateID) { result in
                promise(result)
            }
        }
        let rate = try XCTUnwrap(result.get())

        // Then
        XCTAssertEqual(rate.id, 72)
        XCTAssertEqual(rate.country, "US")
        XCTAssertEqual(rate.state, "AL")
        XCTAssertEqual(rate.postcode, "35041")
        XCTAssertEqual(rate.city, "Cardiff")
        XCTAssertEqual(rate.postcodes, ["35014", "35036", "35041"])
        XCTAssertEqual(rate.rate, "4.0000")
        XCTAssertEqual(rate.name, "State Tax")
        XCTAssertEqual(rate.priority, 0)
        XCTAssertEqual(rate.compound, false)
        XCTAssertEqual(rate.shipping, false)
        XCTAssertEqual(rate.order, 1)
        XCTAssertEqual(rate.taxRateClass, "standard")
    }
}
