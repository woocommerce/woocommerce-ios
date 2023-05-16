import Networking
import XCTest

/// Mock for `SitePluginsRemote`.
///
final class MockSitePluginsRemote {
    /// The results to return in `loadPluginsFromWPCOM`.
    private var loadPluginsFromWPCOMResult: Result<[DotcomSitePlugin], Error>?

    /// Returns the value when `loadPluginsFromWPCOM` is called.
    func whenLoadingPluginsFromWPCOM(thenReturn result: Result<[DotcomSitePlugin], Error>) {
        loadPluginsFromWPCOMResult = result
    }
}

extension MockSitePluginsRemote: SitePluginsRemoteProtocol {
    func loadPluginsFromWPCOM(siteID: Int64) async throws -> [Networking.DotcomSitePlugin] {
        guard let result = loadPluginsFromWPCOMResult else {
            XCTFail("Could not find result for loading site plugins from WPCOM.")
            throw NetworkError.notFound
        }
        return try result.get()
    }

    func loadPlugins(for siteID: Int64, completion: @escaping (Result<[Networking.SitePlugin], Error>) -> Void) {
        // Not implemented
    }

    func installPlugin(for siteID: Int64, slug: String, completion: @escaping (Result<Networking.SitePlugin, Error>) -> Void) {
        // Not implemented
    }

    func activatePlugin(for siteID: Int64, pluginName: String, completion: @escaping (Result<Networking.SitePlugin, Error>) -> Void) {
        // Not implemented
    }

    func getPluginDetails(for siteID: Int64, pluginName: String, completion: @escaping (Result<Networking.SitePlugin, Error>) -> Void) {
        // Not implemented
    }
}
