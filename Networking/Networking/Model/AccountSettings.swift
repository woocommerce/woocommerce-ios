import Foundation

/// WordPress.com Account Settings
///
public struct AccountSettings: Decodable {

    /// Dotcom UserID
    ///
    public let userID: Int64

    /// Tracks analytics opt out dotcom setting
    ///
    public let tracksOptOut: Bool


    /// Default initializer for AccountSettings.
    ///
    public init(userID: Int64, tracksOptOut: Bool) {
        self.userID = userID
        self.tracksOptOut = tracksOptOut
    }


    /// The public initializer for AccountSettings.
    ///
    public init(from decoder: Decoder) throws {
        guard let userID = decoder.userInfo[.userID] as? Int64 else {
            throw AccountSettingsDecodingError.missingUserID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tracksOptOut = try container.decode(Bool.self, forKey: .tracksOptOut)

        self.init(userID: userID, tracksOptOut: tracksOptOut)
    }
}


/// Defines all of the AccountSettings CodingKeys
///
private extension AccountSettings {

    enum CodingKeys: String, CodingKey {
        case userID         = "UserID"
        case tracksOptOut   = "tracks_opt_out"
    }
}


// MARK: - Equatable Conformance
//
extension AccountSettings: Equatable {

    public static func == (lhs: AccountSettings, rhs: AccountSettings) -> Bool {
        return lhs.userID == rhs.userID &&
            lhs.tracksOptOut == rhs.tracksOptOut
    }
}


// MARK: - Decoding Errors
//
enum AccountSettingsDecodingError: Error {
    case missingUserID
}
