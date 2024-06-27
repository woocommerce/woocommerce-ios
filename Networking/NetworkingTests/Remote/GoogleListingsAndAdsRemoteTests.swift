import XCTest
@testable import Networking

final class GoogleListingsAndAdsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Check connection

    func test_checkConnection_returns_parsed_connection() async throws {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let suffix = "wc/gla/ads/connection"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "gla-connection-with-data-envelope")

        // When
        let results = try await remote.checkConnection(for: sampleSiteID)

        // Then
        XCTAssertEqual(results, GoogleAdsConnection(id: 3904318964, currency: "USD", symbol: "$", rawStatus: "incomplete"))
    }

    func test_checkConnection_properly_relays_networking_errors() async {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "wc/gla/ads/connection"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.checkConnection(for: sampleSiteID)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

}
