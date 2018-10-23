import Foundation


/// Mapper: SiteSettings
///
struct SiteSettingsMapper: Mapper {

    /// Site Identifier associated to the settings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't really return the SiteID in any of the
    /// settings endpoints.
    ///
    let siteID: Int


    /// (Attempts) to convert a dictionary into [SiteSetting].
    ///
    func map(response: Data) throws -> [SiteSetting] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(SiteSettingsEnvelope.self, from: response).settings
    }
}


/// SiteSettingsEnvelope Disposable Entity:
/// The settings endpoint returns the settings document within a `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct SiteSettingsEnvelope: Decodable {
    let settings: [SiteSetting]

    private enum CodingKeys: String, CodingKey {
        case settings = "data"
    }
}
