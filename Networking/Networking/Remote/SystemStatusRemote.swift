import Foundation

/// System Status: Remote Endpoint
///
public class SystemStatusRemote: Remote {

    /// Retrieves information from the system status that belongs to the current site.
    /// Currently fetching:
    ///   - Store ID
    ///   - Active Plugins
    ///   - Inactive Plugins
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the system plugins.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadSystemInformation(for siteID: Int64,
                                      completion: @escaping (Result<SystemStatus, Error>) -> Void) {
        let path = Constants.systemStatusPath
        let parameters = [
            ParameterKeys.fields: [ParameterValues.environment, ParameterValues.activePlugins, ParameterValues.inactivePlugins]
        ]
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = SystemStatusMapper(siteID: siteID)

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
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
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
        static let environment: String = "environment"
    }

    enum ParameterKeys {
        static let fields: String = "_fields"
    }
}
