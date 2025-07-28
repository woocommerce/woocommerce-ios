import Networking
import XCTest

/// Mock for `SitePluginsRemote`.
///
final class MockSitePluginsRemote {
}

extension MockSitePluginsRemote: SitePluginsRemoteProtocol {
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
