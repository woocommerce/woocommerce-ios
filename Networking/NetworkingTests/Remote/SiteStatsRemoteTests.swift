import XCTest
@testable import Networking


/// SiteStatsRemote Unit Tests
///
class SiteStatsRemoteTests: XCTestCase {

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
        let remote = SiteStatsRemote(network: network)
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
        let remote = SiteStatsRemote(network: network)

        // When
        let result: Result<SiteVisitStats, Error> = waitFor { promise in
            remote.loadSiteVisitorStats(for: self.sampleSiteID, unit: .day, latestDateToInclude: Date(), quantity: 12) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that loadSiteSummaryStats properly parses the `SiteSummaryStats` sample response.
    ///
    func test_loadSiteSummaryStats_properly_returns_parsed_stats() throws {
        // Given
        let remote = SiteStatsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/summary/", filename: "site-summary-stats")

        // When
        let result: Result<SiteSummaryStats, Error> = waitFor { promise in
            remote.loadSiteSummaryStats(for: self.sampleSiteID, period: .day, includingDate: Date()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteSummaryStats = try result.get()
        XCTAssertEqual(siteSummaryStats.visitors, 12)
        XCTAssertEqual(siteSummaryStats.views, 123)
    }

    /// Verifies that loadSiteSummaryStats properly relays Networking Layer errors.
    ///
    func test_loadSiteSummaryStats_properly_relays_networking_errors() {
        // Given
        let remote = SiteStatsRemote(network: network)

        // When
        let result: Result<SiteSummaryStats, Error> = waitFor { promise in
            remote.loadSiteSummaryStats(for: self.sampleSiteID, period: .day, includingDate: Date()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
