import Foundation
import Codegen

/// Site-specific User representation
///
public struct User: Decodable, GeneratedFakeable {
    /// Local ID of the account on the user's site
    ///
    public let localID: Int64

    /// Linked dotcom site ID
    ///
    public let siteID: Int64

    /// Linked dotcom account ID
    ///
    public let wpcomID: Int64

    /// User's email
    ///
    public let email: String

    /// User's username on the site
    ///
    public let username: String

    /// User's first name
    ///
    public let firstName: String

    /// User's last name
    ///
    public let lastName: String

    /// User's preferred display name
    ///
    public let nickname: String

    /// User's roles
    ///
    public let roles: [String]

    /// Designated Initializer
    ///
    public init(localID: Int64,
                siteID: Int64,
                wpcomID: Int64,
                email: String,
                username: String,
                firstName: String,
                lastName: String,
                nickname: String,
                roles: [String]) {
        self.localID = localID
        self.siteID = siteID
        self.wpcomID = wpcomID
        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.nickname = nickname
        self.roles = roles
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw UserDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(localID: try container.decode(Int64.self, forKey: .localID),
                  siteID: siteID,
                  wpcomID: try container.decode(Int64.self, forKey: .wpcomID),
                  email: try container.decode(String.self, forKey: .email),
                  username: try container.decode(String.self, forKey: .username),
                  firstName: try container.decode(String.self, forKey: .firstName),
                  lastName: try container.decode(String.self, forKey: .lastName),
                  nickname: try container.decode(String.self, forKey: .nickname),
                  roles: try container.decode([String].self, forKey: .roles)
        )
    }
}

private extension User {
    enum CodingKeys: String, CodingKey {
        case localID    = "id"
        case siteID
        case wpcomID    = "id_wpcom"
        case email
        case username
        case firstName  = "first_name"
        case lastName   = "last_name"
        case nickname
        case roles
    }
}

// MARK: - Comparable Conformance
//
extension User: Comparable {
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.localID == rhs.localID &&
            lhs.siteID == rhs.siteID &&
            lhs.wpcomID == rhs.wpcomID &&
            lhs.email == rhs.email &&
            lhs.username == rhs.username &&
            lhs.firstName == rhs.firstName &&
            lhs.lastName == rhs.lastName &&
            lhs.nickname == rhs.nickname &&
            lhs.roles == rhs.roles
    }

    public static func < (lhs: User, rhs: User) -> Bool {
        return lhs.wpcomID < rhs.wpcomID ||
            (lhs.wpcomID == rhs.wpcomID && lhs.username < rhs.username) ||
            (lhs.wpcomID == rhs.wpcomID && lhs.username == rhs.username && lhs.nickname < rhs.nickname)
    }
}


// MARK: - Decoding Errors
//
enum UserDecodingError: Error {
    case missingSiteID
}
