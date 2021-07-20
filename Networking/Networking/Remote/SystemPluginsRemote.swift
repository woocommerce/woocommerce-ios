import Foundation

/// SystemPlugins: Remote Endpoints
///
public class SystemPluginsRemote: Remote {

    /// Retrieves all of the `SystemPlugin`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the system plugins.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadSystemPlugins(for siteID: Int64,
                            completion: @escaping (Result<[SystemPlugin], Error>) -> Void) {
        let path = Constants.systemPluginsPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = SystemPluginsMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension SystemPluginsRemote {
    enum Constants {
        static let systemPluginsPath: String = "system_status"
    }
}
