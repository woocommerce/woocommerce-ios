import Foundation
@testable import Yosemite
@testable import Networking

final class MockWordPressSiteRemote: WordPressSiteRemoteProtocol {
    private var mockedSiteInfo: WordPressSite?
    private var mockedError: Error?

    func mockSiteInfo(_ info: WordPressSite) {
        mockedSiteInfo = info
    }

    func mockFailure(error: Error) {
        mockedSiteInfo = nil
        mockedError = error
    }

    func fetchSiteInfo(for siteURL: String) async throws -> WordPressSite {
        guard let mockedSiteInfo else {
            throw mockedError ?? NetworkError.notFound
        }
        return mockedSiteInfo
    }
}
