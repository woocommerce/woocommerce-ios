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
        let parameters = [
            ParameterKeys.fields: ParameterValues.activeFieldValues
        ]
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
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

    enum ParameterValues {
        static let activeFieldValues: String = "active_plugins"
    }

    enum ParameterKeys {
        static let fields: String = "_fields"
    }
}
