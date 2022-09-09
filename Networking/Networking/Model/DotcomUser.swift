import Codegen
import Foundation

/// Basic information of a WordPress.com user
public struct DotcomUser: Decodable, GeneratedFakeable, GeneratedCopiable {

    /// User ID in WP.com
    public let id: Int64

    /// Username in WP.com
    public let username: String

    /// Registered email address with WP.com
    public let email: String

    /// Display name in WP.com
    public let displayName: String

    /// Link to avatar used in WP.com
    public let avatar: String?

    /// Member-wise initializer
    public init(id: Int64, username: String, email: String, displayName: String, avatar: String?) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.avatar = avatar
    }
}

/// Defines all of the `WordPressComUser` CodingKeys.
///
private extension DotcomUser {

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case username = "login"
        case email
        case displayName = "display_name"
        case avatar
    }
}
