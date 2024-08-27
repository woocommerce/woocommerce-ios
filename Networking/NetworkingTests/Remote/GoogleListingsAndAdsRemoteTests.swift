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

    // MARK: - Fetch ads campaigns

    func test_fetchAdsCampaigns_returns_parsed_connection() async throws {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let suffix = "wc/gla/ads/campaigns"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "gla-campaign-list-with-data-envelope")

        // When
        let results = try await remote.fetchAdsCampaigns(for: sampleSiteID)

        // Then
        let expectedCampaigns = [
            GoogleAdsCampaign(id: 21401695859,
                              name: "Campaign 2024-06-21 04:26:32",
                              rawStatus: "enabled",
                              rawType: "performance_max",
                              amount: 10,
                              country: "US",
                              targetedLocations: ["US"]),
            GoogleAdsCampaign(id: 21402492606,
                              name: "Campaign 2024-06-24 05:08:41",
                              rawStatus: "disabled",
                              rawType: "performance_max",
                              amount: 30,
                              country: "US",
                              targetedLocations: ["US"])
        ]
        XCTAssertEqual(results, expectedCampaigns)
    }

    func test_fetchAdsCampaigns_properly_relays_networking_errors() async {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "wc/gla/ads/campaigns"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.fetchAdsCampaigns(for: sampleSiteID)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - Load campaign stats

    func test_loadCampaignStats_returns_parsed_stats() async throws {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let suffix = "wc/gla/ads/reports/programs"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "google-ads-reports-programs-without-data")

        // When
        let results = try await remote.loadCampaignStats(for: sampleSiteID,
                                                         campaignIDs: [],
                                                         timeZone: .current,
                                                         earliestDateToInclude: Date(),
                                                         latestDateToInclude: Date(),
                                                         orderby: .sales)

        // Then
        XCTAssertEqual(results.siteID, sampleSiteID)
        XCTAssertEqual(results.totals, GoogleAdsCampaignStatsTotals(sales: 11, spend: 73.01, clicks: 154, impressions: 16938, conversions: 3))
        XCTAssertEqual(results.campaigns.count, 2)
    }

    func test_loadCampaignStats_excludes_next_page_parameter_when_not_provided() async throws {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let suffix = "wc/gla/ads/reports/programs"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "google-ads-reports-programs-without-data")

        // When
        _ = try await remote.loadCampaignStats(for: sampleSiteID,
                                               campaignIDs: [],
                                               timeZone: .current,
                                               earliestDateToInclude: Date(),
                                               latestDateToInclude: Date(),
                                               orderby: .sales)

        // Then
        let excludedParam = "next_page"
        let queryParameters = try XCTUnwrap(network.queryParameters)
        XCTAssertFalse(queryParameters.contains(where: { $0.contains(excludedParam) }), "Query parameters contain unexpected param: \(excludedParam)")
    }

    func test_loadCampaignStats_excludes_ids_parameter_when_not_provided() async throws {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let suffix = "wc/gla/ads/reports/programs"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "google-ads-reports-programs-without-data")

        // When
        _ = try await remote.loadCampaignStats(for: sampleSiteID,
                                               campaignIDs: [],
                                               timeZone: .current,
                                               earliestDateToInclude: Date(),
                                               latestDateToInclude: Date(),
                                               orderby: .sales)

        // Then
        let excludedParam = "ids"
        let queryParameters = try XCTUnwrap(network.queryParameters)
        XCTAssertFalse(queryParameters.contains(where: { $0.contains(excludedParam) }), "Query parameters contain unexpected param: \(excludedParam)")
    }

    func test_loadCampaignStats_includes_ids_parameter_when_provided() async throws {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let suffix = "wc/gla/ads/reports/programs"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "google-ads-reports-programs-without-data")

        // When
        _ = try await remote.loadCampaignStats(for: sampleSiteID,
                                               campaignIDs: [135],
                                               timeZone: .current,
                                               earliestDateToInclude: Date(),
                                               latestDateToInclude: Date(),
                                               orderby: .sales)

        // Then
        let queryParameters = try XCTUnwrap(network.queryParametersDictionary)
        XCTAssertEqual(queryParameters["ids"] as? [Int64], [135])
    }

    func test_loadCampaignStats_includes_next_page_parameter_when_provided() async throws {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let suffix = "wc/gla/ads/reports/programs"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "google-ads-reports-programs-without-data")
        let nextPageToken = "abcdefg"

        // When
        _ = try await remote.loadCampaignStats(for: sampleSiteID,
                                               campaignIDs: [],
                                               timeZone: .current,
                                               earliestDateToInclude: Date(),
                                               latestDateToInclude: Date(),
                                               orderby: .sales,
                                               nextPageToken: nextPageToken)

        // Then
        let expectedParam = "next_page=\(nextPageToken)"
        let queryParameters = try XCTUnwrap(network.queryParameters)
        XCTAssertTrue(queryParameters.contains(expectedParam), "Query parameters missing expected param: \(expectedParam)")
    }

    func test_loadCampaignStats_properly_relays_networking_errors() async {
        // Given
        let remote = GoogleListingsAndAdsRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "wc/gla/ads/reports/programs"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.loadCampaignStats(for: sampleSiteID,
                                                   campaignIDs: [],
                                                   timeZone: .current,
                                                   earliestDateToInclude: Date(),
                                                   latestDateToInclude: Date(),
                                                   orderby: .sales)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }
}
