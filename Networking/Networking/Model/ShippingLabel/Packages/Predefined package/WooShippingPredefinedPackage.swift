import Foundation
import Codegen
import WooFoundation

/// Represents a predefined Shipping Label Packages for the WooCommerce Shipping extension.
///
public struct WooShippingPredefinedPackage: Equatable, GeneratedFakeable, Identifiable {

    /// The id of the predefined package
    public let id: String

    /// The name of the package, like `USPS Priority Mail Boxes`
    public let name: String

    /// Defines if package is a box or a letter. By default is a box, so it's equal to `false`
    public let isLetter: Bool

    /// Will be a string formatted like this: `21.91 x 13.65 x 4.13`
    public let dimensions: String

    /// Will be a string formatted like this: `21.91 x 13.65 x 4.13`
    public let outerDimensions: String

    /// Will be a string formatted like this: `21.91 x 13.65 x 4.13`
    public let innerDimensions: String

    public let boxWeight: String

    public let maxWeight: String

    // Will be a string for the groupId, like `pri_flat_boxes`
    public let groupId: String

    public let isFlatRate: Bool?

    public let canShipInternational: Bool?

    public init(id: String,
                name: String,
                isLetter: Bool,
                dimensions: String,
                outerDimensions: String,
                innerDimensions: String,
                boxWeight: String,
                maxWeight: String,
                groupId: String,
                isFlatRate: Bool?,
                canShipInternational: Bool?) {
        self.id = id
        self.name = name
        self.isLetter = isLetter
        self.dimensions = dimensions
        self.outerDimensions = outerDimensions
        self.innerDimensions = innerDimensions
        self.boxWeight = boxWeight
        self.maxWeight = maxWeight
        self.groupId = groupId
        self.isFlatRate = isFlatRate
        self.canShipInternational = canShipInternational
    }

    public func getLength() -> Double {
        let firstComponent = dimensions.components(separatedBy: " x ").first ?? ""
        return Double(firstComponent) ?? 0
    }

    public func getWidth() -> Double {
        let secondComponent = dimensions.components(separatedBy: " x ")[safe: 1] ?? ""
        return Double(secondComponent) ?? 0
    }

    public func getHeight() -> Double {
        let lastComponent = dimensions.components(separatedBy: " x ").last ?? ""
        return Double(lastComponent) ?? 0
    }
}

// MARK: Decodable

extension WooShippingPredefinedPackage: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let isLetter = try container.decodeIfPresent(Bool.self, forKey: .isLetter) ?? false
        let dimensions = try container.decode(String.self, forKey: .dimensions)
        let outerDimensions = try container.decode(String.self, forKey: .outerDimensions)
        let innerDimensions = try container.decode(String.self, forKey: .innerDimensions)
        let groupId = try container.decode(String.self, forKey: .groupId)
        let boxWeight = try container.decode(String.self, forKey: .boxWeight)
        let maxWeight = try container.decode(String.self, forKey: .maxWeight)
        let isFlatRate = try container.decodeIfPresent(Bool.self, forKey: .isFlatRate)
        let canShipInternational = try container.decodeIfPresent(Bool.self, forKey: .isFlatRate)

        self.init(id: id,
                  name: name,
                  isLetter: isLetter,
                  dimensions: dimensions,
                  outerDimensions: outerDimensions,
                  innerDimensions: innerDimensions,
                  boxWeight: boxWeight,
                  maxWeight: maxWeight,
                  groupId: groupId,
                  isFlatRate: isFlatRate,
                  canShipInternational: canShipInternational)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isLetter = "is_letter"
        case dimensions
        case outerDimensions = "outer_dimensions"
        case innerDimensions = "inner_dimensions"
        case groupId = "group_id"
        case boxWeight = "box_weight"
        case maxWeight = "max_weight"
        case isFlatRate = "is_flat_rate"
        case canShipInternational = "can_ship_international"
    }
}
