import Foundation

/// Mapper: System Plugins
///
struct SystemPluginMapper: Mapper {

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

        let systemStatus: SystemStatus = try {
            if hasDataEnvelope(in: response) {
                return try decoder.decode(SystemStatusEnvelope.self, from: response).systemStatus
            } else {
                return try decoder.decode(SystemStatus.self, from: response)
            }
        }()

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
