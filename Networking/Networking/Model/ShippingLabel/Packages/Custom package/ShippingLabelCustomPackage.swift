import Foundation

/// Represents a custom package in Shipping Labels.
///
public struct ShippingLabelCustomPackage: Equatable, GeneratedFakeable {

    /// Usually is always `true` for custom packages
    public let isUserDefined: Bool

    /// The name of the custom package, like `Krabica`
    public let title: String

    /// Defines if package is a box or a letter. By default is a box, so it's equal to `false`
    public let isLetter: Bool

    /// Will be a string formatted like this: `2 x 3 x 4`
    public let dimensions: String

    public let boxWeight: Double

    public let maxWeight: Double

    public init(isUserDefined: Bool, title: String, isLetter: Bool, dimensions: String, boxWeight: Double, maxWeight: Double) {
        self.isUserDefined = isUserDefined
        self.title = title
        self.isLetter = isLetter
        self.dimensions = dimensions
        self.boxWeight = boxWeight
        self.maxWeight = maxWeight
    }
}

// MARK: Decodable
extension ShippingLabelCustomPackage: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let isUserDefined = try container.decode(Bool.self, forKey: .isUserDefined)
        let title = try container.decode(String.self, forKey: .title)
        let isLetter = try container.decodeIfPresent(Bool.self, forKey: .isLetter) ?? false
        let dimensions = try container.decode(String.self, forKey: .innerDimensions)
        let boxWeight = try container.decode(Double.self, forKey: .boxWeight)
        let maxWeight = try container.decode(Double.self, forKey: .maxWeight)

        self.init(isUserDefined: isUserDefined, title: title, isLetter: isLetter, dimensions: dimensions, boxWeight: boxWeight, maxWeight: maxWeight)
    }

    private enum CodingKeys: String, CodingKey {
        case isUserDefined = "is_user_defined"
        case title = "name"
        case isLetter = "is_letter"
        case innerDimensions = "inner_dimensions"
        case boxWeight = "box_weight"
        case maxWeight = "max_weight"
    }
}
