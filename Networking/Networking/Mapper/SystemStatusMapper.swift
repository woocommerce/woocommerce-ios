import Foundation

/// Mapper: System Status
///
struct SystemStatusMapper: Mapper {

    /// Site Identifier associated to the system plugins that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID in the system plugin endpoint.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [SystemPlugin].
    ///
    func map(response: Data) throws -> [SystemPlugin] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        let systemStatus = try decoder.decode(SystemStatusEnvelope.self, from: response).systemStatus

        /// Active and in-active plugins share identical structure, but are stored in separate parts of the remote response
        /// (and without an active attribute in the response). So... we use the same decoder for active and in-active plugins
        /// and here we apply the correct value for active (or not)
        ///
        let activePlugins = systemStatus.activePlugins.map {
            $0.copy(active: true)
        }

        let inactivePlugins = systemStatus.inactivePlugins.map {
            $0.copy(active: false)
        }

        return activePlugins + inactivePlugins
    }
}

/// System Status endpoint returns the requested account in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct SystemStatusEnvelope: Decodable {
    let systemStatus: SystemStatus

    private enum CodingKeys: String, CodingKey {
        case systemStatus = "data"
    }
}
