import Codegen
import Foundation

/// Information of a WP.com user connected to a site's Jetpack if exists
public struct JetpackUser: Decodable, GeneratedFakeable, GeneratedCopiable {

    /// Whether the user has connected a WP.com account to the site's Jetpack
    public let isConnected: Bool

    /// Whether the user is the primary account connected to the site's Jetpack
    public let isMaster: Bool

    /// WP.org username in the site.
    public let username: String

    /// The connected WP.com user if exists
    public let wpcomUser: DotComUser?

    /// Gravatar link of the user
    public let gravatar: String?

    /// Member-wise initializer
    public init(isConnected: Bool, isMaster: Bool, username: String, wpcomUser: DotComUser?, gravatar: String?) {
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
        wpcomUser = try? container.decode(DotComUser.self, forKey: .wpcomUser)
        gravatar = try? container.decode(String.self, forKey: .gravatar)
    }
}

/// Defines all of the `JetpackConnectedUser` CodingKeys.
///
private extension JetpackUser {

    enum CodingKeys: String, CodingKey {
        case isConnected
        case isMaster
        case username
        case wpcomUser
        case gravatar
    }
}
