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

        return try decoder.decode(SystemPluginsEnvelope.self, from: response).data.activePlugins
    }
}

/// SystemPluginsActivePluginsEnvelope Disposable Entity:
/// The plugins endpoint returns the document within a `active_plugins` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct SystemPluginsActivePluginsEnvelope: Decodable {

    let activePlugins: [SystemPlugin]

    private enum CodingKeys: String, CodingKey {
        case activePlugins = "active_plugins"
    }
}

/// SystemPluginsEnvelope Disposable Entity:
/// The plugins endpoint returns the document within a `data` key. This entity
/// allows us to do parse the object `SystemPluginsActivePluginsEnvelope`.
///
private struct SystemPluginsEnvelope: Decodable {
    let data: SystemPluginsActivePluginsEnvelope
}
