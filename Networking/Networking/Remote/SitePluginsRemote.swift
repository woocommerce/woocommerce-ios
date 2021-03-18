import Foundation

/// SitePlugins: Remote Endpoints
///
public class SitePluginsRemote: Remote {

    /// Retrieves all of the `SitePlugin`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the plugins.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadPlugins(for siteID: Int64,
                            completion: @escaping (Result<[SitePlugin], Error>) -> Void) {
        let path = Constants.sitePluginsPath
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = SitePluginsMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension SitePluginsRemote {
    enum Constants {
        static let sitePluginsPath: String = "wp/v2/plugins"
    }
}
