import Foundation

/// Mapper: SiteList
///
class SiteListMapper: Mapper {

    /// (Attempts) to convert a dictionary into [Site].
    ///
    func map(response: Data) throws -> [Site] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        return try decoder.decode(SiteListEnvelope.self, from: response).sites
    }
}


/// SiteList Disposable Entity:
/// `Load All Sites` endpoint returns all of its orders within the `sites` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct SiteListEnvelope: Decodable {
    let sites: [Site]

    private enum CodingKeys: String, CodingKey {
        case sites = "sites"
    }
}
