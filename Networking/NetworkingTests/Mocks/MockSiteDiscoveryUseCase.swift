import Foundation
@testable import Networking

final class MockSiteDiscoveryUseCase: SiteDiscoveryUseCaseProtocol {

    private var mockedEndpoint: String?

    func mockRootAPIEndpoint(with result: String) {
        mockedEndpoint = result
    }
    
    func findRootAPIEndpoint(for siteURL: String) async throws -> String {
        guard let mockedEndpoint else {
            throw NetworkError.notFound
        }
        return mockedEndpoint
    }
}
