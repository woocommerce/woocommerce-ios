import XCTest
@testable import Networking


/// TopEarnerStatsRemote Unit Tests
///
class TopEarnerStatsRemoteTests: XCTestCase {

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


    /// Verifies that loadTopEarnersStats properly returns the `topEarnerStats` response.
    ///
    func test_loadTopEarnersStats_properly_returns_parsed_topEarnerStats() async throws {
        // Given
        let remote = TopEarnersStatsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/top-earners", filename: "topEarnerStats")

        // When
        let topEarnerStats = try await remote.loadTopEarnersStats(for: sampleSiteID, unit: .year, latestDateToInclude: "2018", limit: 5)

        // Then
        XCTAssertNotNil(topEarnerStats)
        XCTAssertEqual(topEarnerStats.items.count, 2)
        XCTAssertEqual(topEarnerStats.items[0].productID, 205)
        XCTAssertEqual(topEarnerStats.items[0].quantity, 1)
        XCTAssertEqual(topEarnerStats.items[0].total, 31.20)
    }

    /// Verifies that loadTopEarnersStats properly relays Networking Layer errors.
    ///
    func test_loadTopEarnersStats_properly_relays_networking_errors() async {
        // Given
        let remote = TopEarnersStatsRemote(network: network)
        network.simulateError(requestUrlSuffix: "sites/\(sampleSiteID)/stats/top-earners", error: NetworkError.timeout())

        // When
        do {
            _ = try await remote.loadTopEarnersStats(for: sampleSiteID, unit: .year, latestDateToInclude: "2018", limit: 5)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(error is NetworkError)
        }
    }
}
