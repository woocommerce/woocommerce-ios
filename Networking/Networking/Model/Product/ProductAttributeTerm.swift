import Foundation

/// Represents a `ProductAttributeTerm` entity.
///
public struct ProductAttributeTerm: Equatable, GeneratedFakeable {
    public let siteID: Int64
    public let termID: Int64
    public let name: String
    public let slug: String
    public let count: Int

    /// Member wise initializer.
    ///
    public init(siteID: Int64, termID: Int64, name: String, slug: String, count: Int) {
        self.siteID = siteID
        self.termID = termID
        self.name = name
        self.slug = slug
        self.count = count
    }
}

// MARK: Codable Conformance
extension ProductAttributeTerm: Decodable {
    enum CodingKeys: String, CodingKey {
        case termID = "id"
        case name
        case slug
        case count
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductCategoryDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let termID = try container.decode(Int64.self, forKey: .termID)
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)
        let count = try container.decode(Int.self, forKey: .count)

        self.init(siteID: siteID, termID: termID, name: name, slug: slug, count: count)
    }
}

// MARK: Decoding Errors
//
enum ProductAttributeTermDecodingError: Error {
    case missingSiteID
}
