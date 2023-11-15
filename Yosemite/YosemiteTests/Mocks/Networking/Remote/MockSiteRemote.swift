import Networking
import XCTest

/// Mock for `SiteRemote`.
///
final class MockSiteRemote {
    /// The results to return in `createSite`.
    private var createSiteResult: Result<SiteCreationResponse, Error>?

    /// The results to return in `launchSite`.
    private var launchSiteResult: Result<Void, Error>?

    /// The results to return in `uploadStoreProfilerAnswers`.
    private var uploadStoreProfilerAnswersResult: Result<Void, Error>?

    /// The results to return in `enableFreeTrial`.
    private var enableFreeTrialResult: Result<Void, Error>?

    /// The results to return in `loadSite`.
    private var loadSiteResult: Result<Site, Error>?

    /// The result to return in `updateSiteTitle`
    private var updateSiteTitleResult: Result<Void, Error>?

    /// Returns the value when `createSite` is called.
    func whenCreatingSite(thenReturn result: Result<SiteCreationResponse, Error>) {
        createSiteResult = result
    }

    /// Returns the value when `launchSite` is called.
    func whenLaunchingSite(thenReturn result: Result<Void, Error>) {
        launchSiteResult = result
    }

    /// Returns the value when `enableFreeTrial` is called.
    func whenEnablingFreeTrial(thenReturn result: Result<Void, Error>) {
        enableFreeTrialResult = result
    }

    /// Returns the value when `uploadStoreProfilerAnswers` is called.
    func whenUploadingStoreProfilerAnswers(thenReturn result: Result<Void, Error>) {
        uploadStoreProfilerAnswersResult = result
    }

    /// Returns the value when `loadSite` is called.
    func whenLoadingSite(thenReturn result: Result<Site, Error>) {
        loadSiteResult = result
    }

    func whenUpdatingSiteTitle(thenReturn result: Result<Void, Error>) {
        updateSiteTitleResult = result
    }
}

extension MockSiteRemote: SiteRemoteProtocol {
    func createSite(name: String, flow: SiteCreationFlow) async throws -> SiteCreationResponse {
        guard let result = createSiteResult else {
            XCTFail("Could not find result for creating a site.")
            throw NetworkError.notFound()
        }

        return try result.get()
    }

    func launchSite(siteID: Int64) async throws {
        guard let result = launchSiteResult else {
            XCTFail("Could not find result for launching a site.")
            throw NetworkError.notFound()
        }

        return try result.get()
    }

    func enableFreeTrial(siteID: Int64) async throws {
        guard let result = enableFreeTrialResult else {
            XCTFail("Could not find result for enabling a trial.")
            throw NetworkError.notFound()
        }

        return try result.get()
    }

    func uploadStoreProfilerAnswers(siteID: Int64, answers: Networking.StoreProfilerAnswers) async throws {
        guard let result = uploadStoreProfilerAnswersResult else {
            XCTFail("Could not find result for upload store profiler answers.")
            throw NetworkError.notFound()
        }

        return try result.get()
    }

    func loadSite(siteID: Int64) async throws -> Site {
        guard let result = loadSiteResult else {
            XCTFail("Could not find result for loading a site.")
            throw NetworkError.notFound()
        }

        return try result.get()
    }

    func updateSiteTitle(siteID: Int64, title: String) async throws {
        guard let result = updateSiteTitleResult else {
            XCTFail("Could not find result for updating site title")
            throw NetworkError.notFound()
        }
        return try result.get()
    }
}
