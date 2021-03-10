import Foundation

/// WordPress.com Account Settings
///
public struct AccountSettings: Decodable, Equatable, GeneratedFakeable {

    /// Dotcom UserID
    ///
    public let userID: Int64

    /// Tracks analytics opt out dotcom setting
    ///
    public let tracksOptOut: Bool

    /// First name of the Account
    ///
    public let firstName: String?

    /// Last name of the Account
    ///
    public let lastName: String?


    /// Default initializer for AccountSettings.
    ///
    public init(userID: Int64, tracksOptOut: Bool, firstName: String?, lastName: String?) {
        self.userID = userID
        self.tracksOptOut = tracksOptOut
        self.firstName = firstName
        self.lastName = lastName
    }


    /// The public initializer for AccountSettings.
    ///
    public init(from decoder: Decoder) throws {
        guard let userID = decoder.userInfo[.userID] as? Int64 else {
            throw AccountSettingsDecodingError.missingUserID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tracksOptOut = try container.decode(Bool.self, forKey: .tracksOptOut)
        let firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        let lastName = try container.decodeIfPresent(String.self, forKey: .lastName)

        self.init(userID: userID, tracksOptOut: tracksOptOut, firstName: firstName, lastName: lastName)
    }
}


/// Defines all of the AccountSettings CodingKeys
///
private extension AccountSettings {

    enum CodingKeys: String, CodingKey {
        case userID         = "UserID"
        case tracksOptOut   = "tracks_opt_out"
        case firstName      = "first_name"
        case lastName       = "last_name"
    }
}


// MARK: - Decoding Errors
//
enum AccountSettingsDecodingError: Error {
    case missingUserID
}
