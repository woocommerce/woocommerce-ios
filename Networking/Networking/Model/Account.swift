import Foundation
import Codegen

/// WordPress.com Account
///
public struct Account: Decodable, Equatable, GeneratedFakeable {

    /// Dotcom UserID
    ///
    public let userID: Int64

    /// Display Name
    ///
    public let displayName: String

    /// Account's Email
    ///
    public let email: String

    /// Account's Username
    ///
    public let username: String

    /// Account's Gravatar
    ///
    public let gravatarUrl: String?

    /// Users IP country Code
    /// This setting is not stored in the Storage layer because we don't want to rely on stale value.
    /// But there us no problem on add it later if we believe it will be useful.
    ///
    public let ipCountryCode: String


    /// Designated Initializer.
    ///
    public init(userID: Int64, displayName: String, email: String, username: String, gravatarUrl: String?, ipCountryCode: String) {
        self.userID = userID
        self.displayName = displayName
        self.email = email
        self.username = username
        self.gravatarUrl = gravatarUrl
        self.ipCountryCode = ipCountryCode
    }
}


/// Defines all of the Account CodingKeys
///
private extension Account {

    enum CodingKeys: String, CodingKey {
        case userID         = "ID"
        case displayName    = "display_name"
        case email          = "email"
        case username       = "username"
        case gravatarUrl    = "avatar_URL"
        case ipCountryCode  = "user_ip_country_code"
    }
}
