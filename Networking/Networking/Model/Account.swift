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


    /// Designated Initializer.
    ///
    public init(userID: Int, displayName: String, email: String, username: String, gravatarUrl: String?) {
        self.userID = userID
        self.displayName = displayName
        self.email = email
        self.username = username
        self.gravatarUrl = gravatarUrl
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
    }
}
