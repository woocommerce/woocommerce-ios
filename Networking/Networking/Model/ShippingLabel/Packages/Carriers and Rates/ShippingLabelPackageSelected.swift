import Foundation
import Codegen

/// Represents the package selected that will be sent in Shipping Labels Carriers and Rates endpoint.
///
public struct ShippingLabelPackageSelected: Equatable, GeneratedFakeable {

    public let id: String
    public let boxID: String
    public let length: Double
    public let width: Double
    public let height: Double
    public let weight: Double
    public let isLetter: Bool
    public let customsForm: ShippingLabelCustomsForm?

    public init(id: String,
                boxID: String,
                length: Double,
                width: Double,
                height: Double,
                weight: Double,
                isLetter: Bool,
                customsForm: ShippingLabelCustomsForm?) {
        self.id = id
        self.boxID = boxID
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight
        self.isLetter = isLetter
        self.customsForm = customsForm
    }
}

// MARK: Codable
extension ShippingLabelPackageSelected: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(boxID, forKey: .boxID)
        try container.encode(length, forKey: .length)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(weight, forKey: .weight)
        try container.encode(isLetter, forKey: .isLetter)
        if let form = customsForm {
            try container.encode(form.contentsType.rawValue, forKey: .contentsType)
            try container.encode(form.contentExplanation, forKey: .contentsExplanation)
            try container.encode(form.restrictionType.rawValue, forKey: .restrictionType)
            try container.encode(form.restrictionComments, forKey: .restrictionComments)
            try container.encode(form.nonDeliveryOption.rawValue, forKey: .nonDeliveryOption)
            try container.encode(form.itn, forKey: .itn)
            try container.encode(form.items, forKey: .items)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case boxID = "box_id"
        case length
        case width
        case height
        case weight
        case isLetter = "is_letter"
        case contentsType = "contents_type"
        case contentsExplanation = "contents_explanation"
        case restrictionType = "restriction_type"
        case restrictionComments = "restriction_comments"
        case nonDeliveryOption = "non_delivery_option"
        case itn
        case items
    }
}
