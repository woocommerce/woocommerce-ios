import Foundation


/// Represents a Dimensions Entity.
///
public struct ProductDimension: Decodable {
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
private extension ProductDimension {

    enum CodingKeys: String, CodingKey {
        case length
        case width
        case height
    }
}

// MARK: - Comparable Conformance
//
extension ProductDimension: Comparable {
    public static func == (lhs: ProductDimension, rhs: ProductDimension) -> Bool {
        return lhs.length == rhs.length &&
            lhs.width == rhs.width &&
            lhs.height == rhs.height
    }

    public static func < (lhs: ProductDimension, rhs: ProductDimension) -> Bool {
        return lhs.length < rhs.length ||
            (lhs.length == rhs.length && lhs.width < rhs.width) ||
            (lhs.length == rhs.length && lhs.width == rhs.width && lhs.height < rhs.height)
    }
}
