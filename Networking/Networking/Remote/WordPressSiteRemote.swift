import Foundation

/// Endpoints for WordPress site information.
///
public final class WordPressSiteRemote: Remote {

    private let siteDiscoveryUseCase: SiteDiscoveryUseCaseProtocol

    public init(network: Network,
                siteDiscoveryUseCase: SiteDiscoveryUseCaseProtocol = SiteDiscoveryUseCase()) {
        self.siteDiscoveryUseCase = siteDiscoveryUseCase
        super.init(network: network)
    }

    /// Fetches information for a given site URL by hitting its root API endpoint.
    ///
    public func fetchSiteInfo(for siteURL: String) async throws -> WordPressSite {
        let rootEndpoint = try await siteDiscoveryUseCase.findRootAPIEndpoint(for: siteURL)
        guard let url = URL(string: rootEndpoint) else {
            throw NetworkError.invalidURL
        }
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressSiteMapper()
        return try await enqueue(request, mapper: mapper)
    }
}
