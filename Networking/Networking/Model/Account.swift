import Foundation


/// WordPress.com Account
///
public struct Account: Decodable {

    /// Dotcom UserID
    ///
    public let userID: Int

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
    }
}
