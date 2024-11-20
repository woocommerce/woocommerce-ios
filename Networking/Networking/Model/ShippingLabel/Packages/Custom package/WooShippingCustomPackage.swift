import Foundation
import Codegen
import WooFoundation

/// Represents a custom package in Shipping Labels for the WooCommerce Shipping extension.
///
public struct WooShippingCustomPackage: Equatable, GeneratedFakeable, GeneratedCopiable {

    /// The ID of the custom package.
    public let id: String

    /// The name of the custom package, like `Krabica`. This is a unique value.
    public let name: String

    /// Raw value of the package type (box or envelope).
    public let rawType: String

    /// Will be a string formatted like this: `2 x 3 x 4`
    public let dimensions: String

    /// Weight of the empty package.
    public let boxWeight: Double

    public enum PackageType: String {
        case box
        case envelope
    }

    /// Decoded value of the package type (box or envelope).
    public var type: PackageType {
        PackageType(rawValue: rawType) ?? .box
    }

    public init(id: String, name: String, rawType: String, dimensions: String, boxWeight: Double) {
        self.id = id
        self.name = name
        self.rawType = rawType
        self.dimensions = dimensions
        self.boxWeight = boxWeight
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

// MARK: Codable
extension WooShippingCustomPackage: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let type = try container.decode(String.self, forKey: .type)
        let dimensions = try container.decode(String.self, forKey: .dimensions)

        var boxWeight: Double = 0.0
        // Looks like some endpoints have boxWeight as String and some as Double
        if let boxWeightDouble = try? container.decodeIfPresent(Double.self, forKey: .boxWeight) {
            boxWeight = boxWeightDouble
        }
        else if let boxWeightString = try? container.decodeIfPresent(String.self, forKey: .boxWeight),
                let boxWeightDouble = Double(boxWeightString) {
            boxWeight = boxWeightDouble
        }

        self.init(id: id, name: name, rawType: type, dimensions: dimensions, boxWeight: boxWeight)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(dimensions, forKey: .dimensions)
        try container.encode(boxWeight, forKey: .boxWeight)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case dimensions
        case boxWeight
    }
}
