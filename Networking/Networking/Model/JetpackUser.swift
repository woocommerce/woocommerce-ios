import Codegen
import Foundation

/// Information of a WP.com user connected to a site's Jetpack if exists
public struct JetpackUser: Decodable, GeneratedFakeable, GeneratedCopiable {

    /// Whether the user has connected a WP.com account to the site's Jetpack
    public let isConnected: Bool

    /// Whether the user is the primary account connected to the site's Jetpack
    public let isPrimary: Bool

    /// WP.org username in the site.
    public let username: String

    /// The connected WP.com user if exists
    public let wpcomUser: DotcomUser?

    /// Gravatar link of the user
    public let gravatar: String?

    /// Member-wise initializer
    public init(isConnected: Bool, isPrimary: Bool, username: String, wpcomUser: DotcomUser?, gravatar: String?) {
        self.isConnected = isConnected
        self.isPrimary = isPrimary
        self.username = username
        self.wpcomUser = wpcomUser
        self.gravatar = gravatar
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isConnected = try container.decode(Bool.self, forKey: .isConnected)
        isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        username = try container.decode(String.self, forKey: .username)
        wpcomUser = try? container.decode(DotcomUser.self, forKey: .wpcomUser)
        gravatar = try? container.decode(String.self, forKey: .gravatar)
    }
}

/// Defines all of the `JetpackUser` CodingKeys.
///
private extension JetpackUser {

    enum CodingKeys: String, CodingKey {
        case isConnected
        case isPrimary = "isMaster"
        case username
        case wpcomUser
        case gravatar
    }
}
