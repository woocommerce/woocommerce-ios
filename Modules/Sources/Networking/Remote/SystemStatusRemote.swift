import Foundation

/// System Status: Remote Endpoint
///
public class SystemStatusRemote: Remote {
    /// Fields that can be requested in the app from the system status endpoint.
    /// Reference of all supported fields: https://woocommerce.github.io/woocommerce-rest-api-docs/#system-status-properties
    public enum Field {
        case activePlugins
        case inactivePlugins
        case environment
        case settings
    }

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
        Task { @MainActor in
            do {
                let mapper = SystemStatusMapper(siteID: siteID)
                let systemStatus = try await loadSystemStatus(for: siteID,
                                                              fields: [Field.environment, Field.activePlugins, Field.inactivePlugins],
                                                              mapper: mapper)
                completion(.success(systemStatus))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Fetch details about system status for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which the system status is fetched
    ///   - completion: Closure to be excuted upon completion
    ///
    public func fetchSystemStatusReport(for siteID: Int64,
                                        completion: @escaping (Result<SystemStatusReport, Error>) -> Void) {
        Task { @MainActor in
            do {
                let mapper = SystemStatusReportMapper(siteID: siteID)
                let systemStatus = try await loadSystemStatus(for: siteID,
                                                              fields: nil,
                                                              mapper: mapper)
                completion(.success(systemStatus))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Loads system status information with configurable fields for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which the system status is fetched from.
    ///   - fields: Optional array of fields to fetch. If nil or empty, it fetches all available fields.
    ///   - mapper: Mapper to transform the response data.
    /// - Returns: Mapped object based on the mapper output type.
    /// - Throws: Network or parsing errors.
    ///
    public func loadSystemStatus<T, M: Mapper>(for siteID: Int64,
                                               fields: [Field]? = nil,
                                               mapper: M) async throws -> T where M.Output == T {
        let path = Constants.systemStatusPath
        let parameters: [String: Any]? = {
            if let fields, !fields.isEmpty {
                return [
                    ParameterKeys.fields: fields.map(\.rawValue)
                ]
            } else {
                return nil
            }
        }()
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - Constants!
//
private extension SystemStatusRemote {
    enum Constants {
        static let systemStatusPath: String = "system_status"
    }

    enum ParameterKeys {
        static let fields: String = "_fields"
    }
}

// MARK: - Field Raw Values
//
private extension SystemStatusRemote.Field {
    var rawValue: String {
        switch self {
        case .activePlugins:
            return "active_plugins"
        case .inactivePlugins:
            return "inactive_plugins"
        case .environment:
            return "environment"
        case .settings:
            return "settings"
        }
    }
}
