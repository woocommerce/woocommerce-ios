import Codegen
import Foundation

/// Basic information of a WordPress.com user
public struct WordPressComUser: Decodable, GeneratedFakeable, GeneratedCopiable {

    /// User ID in WP.com
    public let id: Int64

    /// Username in WP.com
    public let username: String

    /// Registered email address with WP.com
    public let email: String

    /// Display name in WP.com
    public let displayName: String

    /// Text direction in WP.com
    public let textDirection: String

    /// Number of registered sites in WP.com
    public let siteCount: Int64

    /// Link to avatar used in WP.com
    public let avatar: String?

    /// Member-wise initializer
    public init(id: Int64, username: String, email: String, displayName: String, textDirection: String, siteCount: Int64, avatar: String?) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.textDirection = textDirection
        self.siteCount = siteCount
        self.avatar = avatar
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int64.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        textDirection = try container.decode(String.self, forKey: .textDirection)
        siteCount = try container.decode(Int64.self, forKey: .siteCount)
        avatar = try? container.decode(String.self, forKey: .avatar)
    }
}

/// Defines all of the `WordPressComUser` CodingKeys.
///
private extension WordPressComUser {

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case username = "login"
        case email
        case displayName = "display_name"
        case textDirection = "text_direction"
        case siteCount = "site_count"
        case avatar
    }
}
