import Foundation

/// Represents a Shipping Method Entity.
///
public struct ShippingMethod: Decodable, Equatable, Hashable {
    public let siteID: Int64

    /// Shipping Method ID
    ///
    public let methodID: String

    /// Shipping Method Title
    ///
    public let title: String

    /// ShippingMethod struct initializer.
    ///
    public init(siteID: Int64,
                methodID: String,
                title: String) {
        self.siteID = siteID
        self.methodID = methodID
        self.title = title
    }

    public init(from decoder: any Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ShippingMethodDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let methodID = try container.decode(String.self, forKey: .methodID)
        let title = try container.decode(String.self, forKey: .title)

        self.init(siteID: siteID,
                  methodID: methodID,
                  title: title)
    }
}

/// Defines all of the ShippingMethod CodingKeys
///
private extension ShippingMethod {
    enum CodingKeys: String, CodingKey {
        case methodID = "id"
        case title
    }
}


// MARK: - Decoding Errors
//
enum ShippingMethodDecodingError: Error {
    case missingSiteID
}
