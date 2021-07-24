import Foundation
import Codegen

/// Represents a Dimensions Entity.
///
public struct ProductDimensions: Codable, Equatable, GeneratedFakeable {
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
