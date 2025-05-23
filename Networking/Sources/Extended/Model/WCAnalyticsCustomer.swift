import Foundation
import Codegen

public struct WCAnalyticsCustomer: Decodable, GeneratedCopiable, GeneratedFakeable {
    /// The siteID for the WCAnalyticsCustomer
    public let siteID: Int64

    /// Unique identifier for the customer, including non-registered customers
    public let customerID: Int64

    /// Unique identifier for the user, only non-zero when the user is registered
    public let userID: Int64

    /// Customer name
    public let name: String?

    /// Customer email
    public let email: String?

    /// Customer username
    public let username: String?

    /// Date customer registered, in GMT
    public let dateRegistered: Date?

    /// Date customer was last active, in GMT
    public let dateLastActive: Date?

    /// Number of orders for the customer
    public let ordersCount: Int

    /// Total amount spent by the customer
    public let totalSpend: Decimal

    /// Average order value for the customer's orders
    public let averageOrderValue: Decimal

    /// Customer country
    public let country: String

    /// Customer region or state
    public let region: String

    /// Customer city
    public let city: String

    /// Customer postcode
    public let postcode: String

    /// WCAnalyticsCustomer struct Initializer
    ///
    public init(siteID: Int64,
                customerID: Int64,
                userID: Int64,
                name: String?,
                email: String?,
                username: String?,
                dateRegistered: Date?,
                dateLastActive: Date?,
                ordersCount: Int,
                totalSpend: Decimal,
                averageOrderValue: Decimal,
                country: String,
                region: String,
                city: String,
                postcode: String) {
        self.siteID = siteID
        self.customerID = customerID
        self.userID = userID
        self.name = name
        self.email = email
        self.username = username
        self.dateRegistered = dateRegistered
        self.dateLastActive = dateLastActive
        self.ordersCount = ordersCount
        self.totalSpend = totalSpend
        self.averageOrderValue = averageOrderValue
        self.country = country
        self.region = region
        self.city = city
        self.postcode = postcode
    }

    /// Public initializer for WCAnalyticsCustomer
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw DecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let customerID = try container.decode(Int64.self, forKey: .customerID)
        let userID = try container.decode(Int64.self, forKey: .userID)
        let name = try container.decode(String.self, forKey: .name)
        let email = try container.decode(String.self, forKey: .email)
        let username = try container.decode(String.self, forKey: .username)
        let dateRegistered = try? container.decode(Date.self, forKey: .dateRegisteredGMT)
        let dateLastActive = try? container.decode(Date.self, forKey: .dateLastActiveGMT)
        let ordersCount = try container.decode(Int.self, forKey: .ordersCount)
        let totalSpend = try container.decode(Decimal.self, forKey: .totalSpend)
        let averageOrderValue = try container.decode(Decimal.self, forKey: .avgOrderValue)
        let country = try container.decode(String.self, forKey: .country)
        let region = try container.decode(String.self, forKey: .region)
        let city = try container.decode(String.self, forKey: .city)
        let postcode = try container.decode(String.self, forKey: .postcode)

        self.init(siteID: siteID,
                  customerID: customerID,
                  userID: userID,
                  name: name,
                  email: email,
                  username: username,
                  dateRegistered: dateRegistered,
                  dateLastActive: dateLastActive,
                  ordersCount: ordersCount,
                  totalSpend: totalSpend,
                  averageOrderValue: averageOrderValue,
                  country: country,
                  region: region,
                  city: city,
                  postcode: postcode)
    }
}

extension WCAnalyticsCustomer {
    enum CodingKeys: String, CodingKey {
        case customerID         = "id"
        case userID             = "user_id"
        case name               = "name"
        case email              = "email"
        case username           = "username"
        case dateRegisteredGMT  = "date_registered_gmt"
        case dateLastActiveGMT  = "date_last_active_gmt"
        case ordersCount        = "orders_count"
        case totalSpend         = "total_spend"
        case avgOrderValue      = "avg_order_value"
        case country            = "country"
        case city               = "city"
        case region             = "state"
        case postcode           = "postcode"
    }

    enum DecodingError: Error {
        case missingSiteID
    }
}
