import Foundation


/// Represents a Dimensions Entity.
///
public struct ProductDimensions: Decodable {
    public let length: String
    public let width: String
    public let height: String

    /// Dimension struct initializer.
    ///
    public init(length: String,
                width: String,
                height: String) {
        self.length = length
        self.width = width
        self.height = height
    }
}

/// Defines all of the Dimensions CodingKeys
///
private extension ProductDimensions {

    enum CodingKeys: String, CodingKey {
        case length
        case width
        case height
    }
}

// MARK: - Comparable Conformance
//
extension ProductDimensions: Comparable {
    public static func == (lhs: ProductDimensions, rhs: ProductDimensions) -> Bool {
        return lhs.length == rhs.length &&
            lhs.width == rhs.width &&
            lhs.height == rhs.height
    }

    public static func < (lhs: ProductDimensions, rhs: ProductDimensions) -> Bool {
        return lhs.length < rhs.length ||
            (lhs.length == rhs.length && lhs.width < rhs.width) ||
            (lhs.length == rhs.length && lhs.width == rhs.width && lhs.height < rhs.height)
    }
}
