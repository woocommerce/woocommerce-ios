import Codegen
import Foundation

/// Information of a WP.com user connected to a site's Jetpack if exists
public struct JetpackConnectedUser: Decodable, GeneratedFakeable, GeneratedCopiable {

    /// Whether the user has connected a WP.com account to the site's Jetpack
    public let isConnected: Bool

    /// Whether the user is the primary account connected to the site's Jetpack
    public let isMaster: Bool

    /// WP.org username in the site.
    public let username: String

    /// ID of the user in the site.
    public let id: Int64

    /// The connected WP.com user if exists
    public let wpcomUser: WordPressComUser?

    /// Gravatar link of the user
    public let gravatar: String?

    /// Member-wise initializer
    public init(id: Int64, isConnected: Bool, isMaster: Bool, username: String, wpcomUser: WordPressComUser?, gravatar: String?) {
        self.id = id
        self.isConnected = isConnected
        self.isMaster = isMaster
        self.username = username
        self.wpcomUser = wpcomUser
        self.gravatar = gravatar
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        isConnected = try container.decode(Bool.self, forKey: .isConnected)
        isMaster = try container.decode(Bool.self, forKey: .isMaster)
        username = try container.decode(String.self, forKey: .username)
        id = try container.decode(Int64.self, forKey: .id)
        wpcomUser = try? container.decode(WordPressComUser.self, forKey: .wpcomUser)
        gravatar = try? container.decode(String.self, forKey: .gravatar)
    }
}

/// Defines all of the `JetpackConnectedUser` CodingKeys.
///
private extension JetpackConnectedUser {

    enum CodingKeys: String, CodingKey {
        case isConnected
        case isMaster
        case username
        case id
        case wpcomUser
        case gravatar
    }
}
