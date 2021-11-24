import Foundation

/// Mapper: SitePlugin
///
struct SitePluginMapper: Mapper {

    /// Site Identifier associated to the plugin that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID in the plugin endpoint.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into SitePlugin.
    ///
    func map(response: Data) throws -> SitePlugin {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(SitePluginEnvelope.self, from: response).plugin
    }
}


/// SitePluginEnvelope Disposable Entity:
/// The plugins endpoint returns the document within a `data` key. This entity
/// allows us to do parse the returned plugin model with JSONDecoder.
///
private struct SitePluginEnvelope: Decodable {
    let plugin: SitePlugin

    private enum CodingKeys: String, CodingKey {
        case plugin = "data"
    }
}
