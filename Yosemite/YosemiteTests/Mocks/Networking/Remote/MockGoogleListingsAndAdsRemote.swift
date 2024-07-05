import XCTest
import Networking

final class MockGoogleListingsAndAdsRemote {

    private var checkingConnectionResult: Result<GoogleAdsConnection, Error>?
    private var fetchingAdsCampaignsResult: Result<[GoogleAdsCampaign], Error>?
    private var loadingCampaignStatsResults: Result<GoogleAdsCampaignStats, Error>?

    private var invocationCountOfLoadingCampaignStats: Int = 0

    func whenCheckingConnection(thenReturn result: Result<GoogleAdsConnection, Error>) {
        checkingConnectionResult = result
    }

    func whenFetchingAdsCampaigns(thenReturn result: Result<[GoogleAdsCampaign], Error>) {
        fetchingAdsCampaignsResult = result
    }

    func whenLoadingCampaignStatsResults(thenReturn result: Result<GoogleAdsCampaignStats, Error>) {
        loadingCampaignStatsResults = result
    }
}

extension MockGoogleListingsAndAdsRemote: GoogleListingsAndAdsRemoteProtocol {
    func loadCampaignStats(for siteID: Int64,
                           campaignIDs: [Int64],
                           timeZone: TimeZone,
                           earliestDateToInclude: Date,
                           latestDateToInclude: Date,
                           totals: [Networking.GoogleListingsAndAdsRemote.StatsField],
                           orderby: Networking.GoogleListingsAndAdsRemote.StatsField,
                           nextPageToken: String?) async throws -> GoogleAdsCampaignStats {
        guard let result = loadingCampaignStatsResults else {
            XCTFail("Could not find result for loading GLA campaign stats.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let stats):
            // If we have already returned a page of stats, make this the final page.
            let stats = invocationCountOfLoadingCampaignStats > 0 ? stats.copy(nextPageToken: .some(nil)) : stats
            invocationCountOfLoadingCampaignStats += 1
            return stats
        case .failure(let error):
            throw error
        }
    }

    func checkConnection(for siteID: Int64) async throws -> Networking.GoogleAdsConnection {
        guard let result = checkingConnectionResult else {
            XCTFail("Could not find result for checking GLA connection.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let connection):
            return connection
        case .failure(let error):
            throw error
        }
    }

    func fetchAdsCampaigns(for siteID: Int64) async throws -> [GoogleAdsCampaign] {
        guard let result = fetchingAdsCampaignsResult else {
            XCTFail("Could not find result for fetching GLA campaigns.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let campaigns):
            return campaigns
        case .failure(let error):
            throw error
        }
    }
}
