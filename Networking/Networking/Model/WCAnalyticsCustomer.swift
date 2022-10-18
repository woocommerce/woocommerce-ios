import Foundation
import Codegen

public struct WCAnalyticsCustomer: Codable, GeneratedCopiable, GeneratedFakeable {

    /// Unique identifier for the user
    public let userID: Int64

    /// Customer name
    public let name: String?

    /// WCAnalyticsCustomer struct Initializer
    ///
    public init(userID: Int64, name: String?) {
        self.userID = userID
        self.name = name
    }

    /// Public initializer for WCAnalyticsCustomer
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let userID = try container.decode(Int64.self, forKey: .userID)
        let name = try container.decode(String.self, forKey: .name)

        self.init(userID: userID, name: name)
    }
}

extension WCAnalyticsCustomer {
    enum CodingKeys: String, CodingKey {
        case userID =   "user_id"
        case name   =   "name"
    }
}
