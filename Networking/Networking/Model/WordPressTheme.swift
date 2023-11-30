import Foundation
import Codegen

/// Details of a WordPress theme
///
public struct WordPressTheme: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// ID of the theme
    public let id: String

    /// Description of the theme
    public let description: String

    /// Name of the theme
    public let name: String

    /// URI of the demo site for the theme
    public let demoURI: String

    public init(id: String,
                description: String,
                name: String,
                demoURI: String) {
        self.id = id
        self.description = description
        self.name = name
        self.demoURI = demoURI
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        description = try container.decode(String.self, forKey: .description)
        name = try container.decode(String.self, forKey: .name)
        demoURI = try container.decodeIfPresent(String.self, forKey: .demoURI) ??
        (try container.decodeIfPresent(String.self, forKey: .themeURI)) ?? ""
    }
}

private extension WordPressTheme {
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case name
        case demoURI = "demo_uri"
        case themeURI = "theme_uri"
    }
}
