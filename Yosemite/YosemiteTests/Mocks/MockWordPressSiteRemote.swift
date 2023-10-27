import Foundation
@testable import Yosemite
@testable import Networking

final class MockWordPressSiteRemote: WordPressSiteRemoteProtocol {
    private var mockedSiteInfo: WordPressSite?

    func mockSiteInfo(_ info: WordPressSite) {
        mockedSiteInfo = info
    }

    func fetchSiteInfo(for siteURL: String) async throws -> WordPressSite {
        guard let mockedSiteInfo else {
            throw NetworkError.notFound
        }
        return mockedSiteInfo
    }
}
