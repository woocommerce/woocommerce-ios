import Foundation

/// WordPress.com Account Settings
///
public struct AccountSettings: Decodable {

    /// Tracks analytics opt out dotcom setting
    ///
    public let tracksOptOut: Bool
}


/// Defines all of the AccountSettings CodingKeys
///
private extension AccountSettings {

    enum CodingKeys: String, CodingKey {
        case tracksOptOut   = "tracks_opt_out"
    }
}



// MARK: - Equatable Conformance
//
extension AccountSettings: Equatable {

    public static func == (lhs: AccountSettings, rhs: AccountSettings) -> Bool {
        return lhs.tracksOptOut == rhs.tracksOptOut
    }
}
