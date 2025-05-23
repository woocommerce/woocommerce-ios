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

    public let boxWeight: String

    // Will be a string for the groupId, like `pri_flat_boxes`
    public let groupId: String

    public init(id: String,
                name: String,
                isLetter: Bool,
                dimensions: String,
                boxWeight: String,
                groupId: String) {
        self.id = id
        self.name = name
        self.isLetter = isLetter
        self.dimensions = dimensions
        self.boxWeight = boxWeight
        self.groupId = groupId
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
        var dimensions: String = ""
        if let dimensionsString = try? container.decodeIfPresent(String.self, forKey: .dimensions) {
            dimensions = dimensionsString
        }
        else if let dimensionsDict = try? container.decodeIfPresent([String: String].self, forKey: .dimensions) {
            if let dimensionsOuter = dimensionsDict["outer"] {
                dimensions = dimensionsOuter
            }
            else if let dimensionsInner = dimensionsDict["inner"] {
                dimensions = dimensionsInner
            }
        }
        else if let outerDimensionsString = try? container.decodeIfPresent(String.self, forKey: .outerDimensions) {
            dimensions = outerDimensionsString
        }
        let groupId = try container.decode(String.self, forKey: .groupId)
        var boxWeight: String = ""
        // Looks like some endpoints have boxWeight as String and some as Double
        if let boxWeightDouble = try? container.decodeIfPresent(Double.self, forKey: .boxWeight) {
            boxWeight = String(boxWeightDouble)
        }
        else if let boxWeightString = try? container.decodeIfPresent(String.self, forKey: .boxWeight) {
            boxWeight = boxWeightString
        }

        self.init(id: id,
                  name: name,
                  isLetter: isLetter,
                  dimensions: dimensions,
                  boxWeight: boxWeight,
                  groupId: groupId)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isLetter = "is_letter"
        case dimensions
        case outer
        case inner
        case groupId = "group_id"
        case boxWeight = "box_weight"
        case outerDimensions = "outer_dimensions"
    }
}
