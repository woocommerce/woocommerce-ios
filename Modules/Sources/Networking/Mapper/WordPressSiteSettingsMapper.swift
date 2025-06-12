import Foundation

/// Mapper: WordPress Site Settings
///
struct WordPressSiteSettingsMapper: Mapper {
    /// (Attempts) to convert a dictionary into `WordPressSiteSettings`.
    func map(response: Data) throws -> WordPressSiteSettings {
        let decoder = JSONDecoder()
        return try decoder.decode(WordPressSiteSettings.self, from: response)
    }
}

/// Represents a WordPress Site Settings response.
///
public struct WordPressSiteSettings: Decodable, Equatable {
    /// Site's Name.
    public let name: String

    /// Site's Description.
    public let description: String

    /// Site's URL.
    public let url: String

    private enum CodingKeys: String, CodingKey {
        case name = "title"
        case description
        case url
    }
}
