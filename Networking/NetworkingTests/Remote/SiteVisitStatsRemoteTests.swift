import XCTest
@testable import Networking


/// SiteVisitStatsRemote Unit Tests
///
class SiteVisitStatsRemoteTests: XCTestCase {

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


    /// Verifies that loadSiteVisitorStats properly parses the `SiteVisitStats` sample response.
    ///
    func test_loadSiteVisitorStats_properly_returns_parsed_stats() throws {
        // Given
        let remote = SiteVisitStatsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits-day")

        // When
        let result: Result<SiteVisitStats, Error> = waitFor { promise in
            remote.loadSiteVisitorStats(for: self.sampleSiteID, unit: .day, latestDateToInclude: Date(), quantity: 12) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteVisitStats = try result.get()
        XCTAssertEqual(siteVisitStats.items?.count, 12)
    }

    /// Verifies that loadSiteVisitorStats properly relays Networking Layer errors.
    ///
    func test_loadSiteVisitorStats_properly_relays_netwoking_errors() {
        // Given
        let remote = SiteVisitStatsRemote(network: network)

        // When
        let result: Result<SiteVisitStats, Error> = waitFor { promise in
            remote.loadSiteVisitorStats(for: self.sampleSiteID, unit: .day, latestDateToInclude: Date(), quantity: 12) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
