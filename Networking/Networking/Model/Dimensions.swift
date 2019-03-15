import Foundation


/// Represents a Dimensions Entity.
///
public struct Dimensions: Decodable {
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
private extension Dimensions {

    enum CodingKeys: String, CodingKey {
        case length
        case width
        case height
    }
}

// MARK: - Comparable Conformance
//
extension Dimensions: Comparable {
    public static func == (lhs: Dimensions, rhs: Dimensions) -> Bool {
        return lhs.length == rhs.length &&
            lhs.width == rhs.width &&
            lhs.height == rhs.height
    }

    public static func < (lhs: Dimensions, rhs: Dimensions) -> Bool {
        return lhs.length < rhs.length ||
            (lhs.length == rhs.length && lhs.width < rhs.width) ||
            (lhs.length == rhs.length && lhs.width == rhs.width && lhs.height < rhs.height)
    }
}
