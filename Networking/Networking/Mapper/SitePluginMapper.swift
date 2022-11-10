import Foundation

/// Mapper: SitePlugin
///
struct SitePluginMapper: Mapper {

    /// Site Identifier associated to the plugin that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID in the plugin endpoint.
    ///
    private let siteID: Int64

    private let withDataEnvelope: Bool

    init(siteID: Int64 = -1, withDataEnvelope: Bool = true) {
        self.siteID = siteID
        self.withDataEnvelope = withDataEnvelope
    }

    /// (Attempts) to convert a dictionary into SitePlugin.
    ///
    func map(response: Data) throws -> SitePlugin {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        if withDataEnvelope {
            return try decoder.decode(SitePluginEnvelope.self, from: response).plugin
        }

        return try decoder.decode(SitePlugin.self, from: response)
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
