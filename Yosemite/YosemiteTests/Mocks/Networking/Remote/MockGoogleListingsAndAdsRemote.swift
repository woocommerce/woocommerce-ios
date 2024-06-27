import XCTest
import Networking

final class MockGoogleListingsAndAdsRemote {

    private var checkingConnectionResult: Result<GoogleAdsConnection, Error>?
    private var fetchingAdsCampaignsResult: Result<[GoogleAdsCampaign], Error>?

    func whenCheckingConnection(thenReturn result: Result<GoogleAdsConnection, Error>) {
        checkingConnectionResult = result
    }

    func whenFetchingAdsCampaigns(thenReturn result: Result<[GoogleAdsCampaign], Error>) {
        fetchingAdsCampaignsResult = result
    }
}

extension MockGoogleListingsAndAdsRemote: GoogleListingsAndAdsRemoteProtocol {
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
