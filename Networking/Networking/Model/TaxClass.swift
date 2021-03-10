import Foundation

/// Represent a Tax Class Entity.
///
public struct TaxClass: Decodable, GeneratedFakeable {

    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int64

    /// Tax class name.
    ///
    public let name: String

    /// Unique identifier for the resource.
    ///
    public let slug: String


    /// Default initializer for TaxClass.
    ///
    public init(siteID: Int64, name: String, slug: String) {
        self.siteID = siteID
        self.name = name
        self.slug = slug
    }


    /// The public initializer for TaxClass.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw TaxClassDecodingError.missingSiteID
        }
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(siteID: siteID, name: name, slug: slug)
    }
}

// MARK: - Equatable Conformance
//
extension TaxClass: Equatable {

    public static func == (lhs: TaxClass, rhs: TaxClass) -> Bool {
        return lhs.name == rhs.name &&
            lhs.slug == rhs.slug
    }
}

/// Defines all of the TaxClass CodingKeys
///
private extension TaxClass {

    enum CodingKeys: String, CodingKey {
        case name
        case slug
    }
}

// MARK: - Decoding Errors
//
enum TaxClassDecodingError: Error {
    case missingSiteID
}
