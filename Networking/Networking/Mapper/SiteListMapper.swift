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
/// Decoding will filter invalid or malformed sites.
///
private struct SiteListEnvelope: Decodable {

    /// Empty struct needed to act as a decoding recipient for a malformed site.
    ///
    struct Empty: Decodable {}

    let sites: [Site]

    private enum CodingKeys: String, CodingKey {
        case sites = "sites"
    }

    /// Decodes and filter invalid/malformed sites
    ///
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var sitesContainer = try container.nestedUnkeyedContainer(forKey: .sites)

        let sites: [Site] = try {
            var sites: [Site] = []
            while !sitesContainer.isAtEnd {
                do {
                    let site = try sitesContainer.decode(Site.self)
                    sites.append(site)
                } catch {
                    // Needed to evict the malformed site from the container.
                    // Update when `.skip()` is available https://github.com/apple/swift/pull/23707
                    _ = try sitesContainer.decode(Empty.self)
                    DDLogError("⛔️ Error decoding site: \(error)")
                }
            }
            return sites
        }()
        self.sites = sites
    }
}
