import XCTest
import Networking

/// Mock for `BlazeRemote`.
///
final class MockBlazeRemote {
    private var loadingCampaignResult: Result<[Networking.BlazeCampaign], Error>?

    func whenLoadingCampaign(thenReturn result: Result<[Networking.BlazeCampaign], Error>) {
        loadingCampaignResult = result
    }
}

extension MockBlazeRemote: BlazeRemoteProtocol {
    func loadCampaigns(for siteID: Int64, pageNumber: Int) async throws -> [Networking.BlazeCampaign] {
        guard let result = loadingCampaignResult else {
            XCTFail("Could not find result for loading Blaze campaigns.")
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
