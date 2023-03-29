import Networking
import XCTest

/// Mock for `SiteRemote`.
///
final class MockSiteRemote {
    /// The results to return in `createSite`.
    private var createSiteResult: Result<SiteCreationResponse, Error>?

    /// The results to return in `launchSite`.
    private var launchSiteResult: Result<Void, Error>?

    /// The results to return in `enableFreeTrial`.
    private var enableFreeTrialResult: Result<Void, Error>?

    /// Returns the value when `createSite` is called.
    func whenCreatingSite(thenReturn result: Result<SiteCreationResponse, Error>) {
        createSiteResult = result
    }

    /// Returns the value when `launchSite` is called.
    func whenLaunchingSite(thenReturn result: Result<Void, Error>) {
        launchSiteResult = result
    }
}

extension MockSiteRemote: SiteRemoteProtocol {
    func createSite(name: String, flow: SiteCreationFlow) async throws -> SiteCreationResponse {
        guard let result = createSiteResult else {
            XCTFail("Could not find result for creating a site.")
            throw NetworkError.notFound
        }

        return try result.get()
    }

    func launchSite(siteID: Int64) async throws {
        guard let result = launchSiteResult else {
            XCTFail("Could not find result for launching a site.")
            throw NetworkError.notFound
        }

        return try result.get()
    }

    func enableFreeTrial(siteID: Int64) async throws {
        guard let result = enableFreeTrialResult else {
            XCTFail("Could not find result for enabling a trial.")
            throw NetworkError.notFound
        }

        return try result.get()
    }
}
