import Foundation

/// Mapper: SitePlugins
///
struct SitePluginsMapper: Mapper {

    /// Site Identifier associated to the plugins that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID in the plugin endpoint.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [SitePlugin].
    ///
    func map(response: Data) throws -> [SitePlugin] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(SitePluginsEnvelope.self, from: response).plugins
    }
}


/// SitePluginsEnvelope Disposable Entity:
/// The plugins endpoint returns the document within a `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct SitePluginsEnvelope: Decodable {
    let plugins: [SitePlugin]

    private enum CodingKeys: String, CodingKey {
        case plugins = "data"
    }
}
