import Foundation
import Codegen

/// Represents the package selected that will be sent in Shipping Labels Carriers and Rates endpoint.
///
public struct ShippingLabelPackageSelected: Equatable, GeneratedFakeable {

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
