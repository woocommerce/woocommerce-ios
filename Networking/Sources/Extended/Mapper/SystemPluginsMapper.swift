import Foundation

/// Mapper: Plugins from System Status
///
struct SystemPluginsMapper: Mapper {

    /// Site Identifier associated to the system status that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID in the system plugin endpoint.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into SystemPlugins
    ///
    func map(response: Data) throws -> SystemPlugins {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(SystemPluginsEnvelope.self, from: response).systemPlugins
        } else {
            return try decoder.decode(SystemPlugins.self, from: response)
        }
    }
}

/// System Status endpoint returns the active/inactive plugins in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
struct SystemPluginsEnvelope: Decodable {
    let systemPlugins: SystemPlugins

    private enum CodingKeys: String, CodingKey {
        case systemPlugins = "data"
    }
}
