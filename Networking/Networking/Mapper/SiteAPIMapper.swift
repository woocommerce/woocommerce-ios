import Foundation


/// Mapper: SiteAPI
///
struct SiteAPIMapper: Mapper {

    /// Site Identifier associated to the API information that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [SiteSetting].
    ///
    func map(response: Data) throws -> SiteAPI {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(SiteAPIEnvelope.self, from: response).siteAPI
    }
}


/// SiteAPIEnvelope Disposable Entity:
/// The settings endpoint returns the settings document within a `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct SiteAPIEnvelope: Decodable {
    let siteAPI: SiteAPI

    private enum CodingKeys: String, CodingKey {
        case siteAPI = "data"
    }
}
