import Foundation

/// Represent a Tax Class Entity.
///
public struct TaxClass: Decodable {

    /// Tax class name.
    ///
    public let name: String

    /// Unique identifier for the resource.
    ///
    public let slug: String


    /// Default initializer for TaxClass.
    ///
    public init(name: String, slug: String) {
        self.name = name
        self.slug = slug
    }


    /// The public initializer for TaxClass.
    ///
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(name: name, slug: slug)
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


// MARK: - Equatable Conformance
//
extension TaxClass: Equatable {

    public static func == (lhs: TaxClass, rhs: TaxClass) -> Bool {
        return lhs.name == rhs.name &&
            lhs.slug == rhs.slug
    }
}
