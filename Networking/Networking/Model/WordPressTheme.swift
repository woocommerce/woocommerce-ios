import Foundation
import Codegen

/// Details of a WordPress theme
///
public struct WordPressTheme: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, Identifiable {

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
        /// We want to reuse the response for WPCom V1.1 themes/mine/ which doesn't have `demo_uri`
        /// so this is decoding can fail silently with an empty string as the default value.
        demoURI = try container.decodeIfPresent(String.self, forKey: .demoURI) ?? ""
    }
}

private extension WordPressTheme {
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case name
        case demoURI = "demo_uri"
    }
}

public extension WordPressTheme {
    var themeThumbnailURL: URL? {
        if self.demoURI.isEmpty {
            return nil
        }

        // Build theme screenshot URL using mShots.
        let urlStr = "https://s0.wp.com/mshots/v1/\(self.demoURI)?demo=true/?w=1200&h=2400&vpw=400&vph=800"
        return URL(string: urlStr)
    }
}
