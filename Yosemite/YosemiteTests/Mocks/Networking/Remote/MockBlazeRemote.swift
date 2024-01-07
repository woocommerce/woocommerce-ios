import XCTest
import Networking

/// Mock for `BlazeRemote`.
///
final class MockBlazeRemote {
    private var creatingCampaignResult: Result<Void, Error>?
    private var loadingCampaignResult: Result<[BlazeCampaign], Error>?
    private var fetchingTargetLanguagesResult: Result<[BlazeTargetLanguage], Error>?
    private var fetchingTargetDevicesResult: Result<[BlazeTargetDevice], Error>?
    private var fetchingTargetTopicsResult: Result<[BlazeTargetTopic], Error>?
    private var fetchingTargetLocationsResult: Result<[BlazeTargetLocation], Error>?
    private var fetchingForecastedImpressionsResult: Result<BlazeImpressions, Error>?

    func whenCreatingCampaign(thenReturn result: Result<Void, Error>) {
        creatingCampaignResult = result
    }

    func whenLoadingCampaign(thenReturn result: Result<[BlazeCampaign], Error>) {
        loadingCampaignResult = result
    }

    func whenFetchingTargetLanguages(thenReturn result: Result<[BlazeTargetLanguage], Error>?) {
        fetchingTargetLanguagesResult = result
    }

    func whenFetchingTargetDevices(thenReturn result: Result<[BlazeTargetDevice], Error>?) {
        fetchingTargetDevicesResult = result
    }

    func whenFetchingTargetTopics(thenReturn result: Result<[BlazeTargetTopic], Error>?) {
        fetchingTargetTopicsResult = result
    }

    func whenFetchingTargetLocations(thenReturn result: Result<[BlazeTargetLocation], Error>?) {
        fetchingTargetLocationsResult = result
    }

    func whenFetchingForecastedImpressions(thenReturn result: Result<BlazeImpressions, Error>?) {
        fetchingForecastedImpressionsResult = result
    }
}

extension MockBlazeRemote: BlazeRemoteProtocol {
    func createCampaign(_ campaign: CreateBlazeCampaign,
                        siteID: Int64) async throws {
        guard let result = creatingCampaignResult else {
            XCTFail("Could not find result for creating campaign.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func fetchTargetLanguages(for siteID: Int64, locale: String) async throws -> [BlazeTargetLanguage] {
        guard let result = fetchingTargetLanguagesResult else {
            XCTFail("Could not find result for fetching target languages.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let languages):
            return languages
        case .failure(let error):
            throw error
        }
    }

    func fetchTargetDevices(for siteID: Int64, locale: String) async throws -> [BlazeTargetDevice] {
        guard let result = fetchingTargetDevicesResult else {
            XCTFail("Could not find result for fetching target devices.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let devices):
            return devices
        case .failure(let error):
            throw error
        }
    }

    func fetchTargetTopics(for siteID: Int64, locale: String) async throws -> [BlazeTargetTopic] {
        guard let result = fetchingTargetTopicsResult else {
            XCTFail("Could not find result for fetching target topics.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let topics):
            return topics
        case .failure(let error):
            throw error
        }
    }

    func fetchTargetLocations(for siteID: Int64, query: String, locale: String) async throws -> [BlazeTargetLocation] {
        guard let result = fetchingTargetLocationsResult else {
            XCTFail("Could not find result for fetching target locations.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let locations):
            return locations
        case .failure(let error):
            throw error
        }
    }

    func fetchForecastedImpressions(
        for siteID: Int64,
        with input: BlazeForecastedImpressionsInput
    ) async throws -> Networking.BlazeImpressions {
        guard let result = fetchingForecastedImpressionsResult else {
            XCTFail("Could not find result for fetching forecasted impressions.")
            throw NetworkError.notFound()
        }

        switch result {
        case .success(let impressions):
            return impressions
        case .failure(let error):
            throw error
        }
    }

    func loadCampaigns(for siteID: Int64, pageNumber: Int) async throws -> [BlazeCampaign] {
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
