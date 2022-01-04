import Foundation

/// System Status: Remote Endpoint
///
public class SystemStatusRemote: Remote {

    /// Retrieves all of the `SystemPlugin`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the system plugins.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadSystemPlugins(for siteID: Int64,
                            completion: @escaping (Result<[SystemPlugin], Error>) -> Void) {
        let path = Constants.systemStatusPath
        let parameters = [
            ParameterKeys.fields: [ParameterValues.activePlugins, ParameterValues.inactivePlugins]
        ]
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = SystemPluginMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Fetch details about system status for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which the system status is fetched
    ///   - completion: Closure to be excuted upon completion
    ///
    public func fetchSystemStatusReport(for siteID: Int64,
                                        completion: @escaping (Result<SystemStatus, Error>) -> Void) {
        let path = Constants.systemStatusPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = SystemStatusMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants!
//
private extension SystemStatusRemote {
    enum Constants {
        static let systemStatusPath: String = "system_status"
    }

    enum ParameterValues {
        static let activePlugins: String = "active_plugins"
        static let inactivePlugins: String = "inactive_plugins"
    }

    enum ParameterKeys {
        static let fields: String = "_fields"
    }
}
