import Foundation


/// Represents a Post Entity.
///
public struct Post: Codable {

    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int64

    public let password: String

    /// Site Post struct initializer.
    ///
    public init(siteID: Int64, password: String) {
        self.siteID = siteID
        self.password = password
    }


    /// The public initializer for Site Post.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let siteID = try container.decode(Int64.self, forKey: .siteID)
        let password = try container.decode(String.self, forKey: .password)

        self.init(siteID: siteID, password: password)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(password, forKey: .password)
    }
}


/// Defines all of the Site Post CodingKeys
///
private extension Post {
    enum CodingKeys: String, CodingKey {
        case siteID         = "site_ID"
        case password       = "password"
    }
}


// MARK: - Comparable Conformance
//
extension Post: Comparable {
    public static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.password == rhs.password
    }

    public static func < (lhs: Post, rhs: Post) -> Bool {
        return lhs.siteID < rhs.siteID
    }

}
