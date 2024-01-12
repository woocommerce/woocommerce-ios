import Foundation
import Codegen

public struct WCAnalyticsCustomer: Codable, GeneratedCopiable, GeneratedFakeable {
    /// The siteID for the WCAnalyticsCustomer
    public let siteID: Int64

    /// Unique identifier for the user, only non-zero when the user is registered
    public let userID: Int64

    /// Customer name
    public let name: String?

    /// Customer email
    public let email: String?

    /// Customer username
    public let username: String?

    /// WCAnalyticsCustomer struct Initializer
    ///
    public init(siteID: Int64, userID: Int64, name: String?, email: String?, username: String?) {
        self.siteID = siteID
        self.userID = userID
        self.name = name
        self.email = email
        self.username = username
    }

    /// Public initializer for WCAnalyticsCustomer
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw DecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let userID = try container.decode(Int64.self, forKey: .userID)
        let name = try container.decode(String.self, forKey: .name)
        let email = try container.decode(String.self, forKey: .email)
        let username = try container.decode(String.self, forKey: .username)

        self.init(siteID: siteID, userID: userID, name: name, email: email, username: username)
    }
}

extension WCAnalyticsCustomer {
    enum CodingKeys: String, CodingKey {
        case userID =   "user_id"
        case name   =   "name"
        case email  =   "email"
        case username = "username"
    }

    enum DecodingError: Error {
        case missingSiteID
    }
}
