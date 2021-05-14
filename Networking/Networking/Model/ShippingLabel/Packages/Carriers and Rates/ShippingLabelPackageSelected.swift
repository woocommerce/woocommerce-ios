import Foundation
import Codegen

/// Represents the package selected that will be sent in Shipping Labels Carriers and Rates endpoint.
///
public struct ShippingLabelPackageSelected: Equatable {

    /// The id will be always "default_box"
    public let id: String = "default_box"
    public let boxID: String
    public let length: Double
    public let width: Double
    public let height: Double
    public let weight: Double
    public let isLetter: Bool

    public init(boxID: String, length: Double, width: Double, height: Double, weight: Double, isLetter: Bool) {
        self.boxID = boxID
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight
        self.isLetter = isLetter
    }

    public init(customPackage: ShippingLabelCustomPackage, totalWeight: Double) {
        self.boxID = customPackage.title
        self.length = customPackage.getLength()
        self.width = customPackage.getWidth()
        self.height = customPackage.getHeight()
        self.weight = totalWeight
        self.isLetter = customPackage.isLetter
    }

    public init(predefinedPackage: ShippingLabelPredefinedPackage, totalWeight: Double) {
        self.boxID = predefinedPackage.id
        self.length = predefinedPackage.getLength()
        self.width = predefinedPackage.getWidth()
        self.height = predefinedPackage.getHeight()
        self.weight = totalWeight
        self.isLetter = predefinedPackage.isLetter
    }
}

// MARK: Codable
extension ShippingLabelPackageSelected: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let boxID = try container.decode(String.self, forKey: .boxID)
        let length = try container.decode(Double.self, forKey: .length)
        let width = try container.decode(Double.self, forKey: .width)
        let height = try container.decode(Double.self, forKey: .height)
        let weight = try container.decode(Double.self, forKey: .weight)
        let isLetter = try container.decode(Bool.self, forKey: .isLetter)

        self.init(boxID: boxID, length: length, width: width, height: height, weight: weight, isLetter: isLetter)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(boxID, forKey: .boxID)
        try container.encode(length, forKey: .length)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(weight, forKey: .weight)
        try container.encode(isLetter, forKey: .isLetter)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case boxID = "box_id"
        case length
        case width
        case height
        case weight
        case isLetter = "is_letter"
    }
}
