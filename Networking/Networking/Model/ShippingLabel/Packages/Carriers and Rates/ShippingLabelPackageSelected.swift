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
    public let customsForm: ShippingLabelCustomsForm?

    public init(boxID: String, length: Double, width: Double, height: Double, weight: Double, isLetter: Bool, customsForm: ShippingLabelCustomsForm?) {
        self.boxID = boxID
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight
        self.isLetter = isLetter
        self.customsForm = customsForm
    }

    public init(customPackage: ShippingLabelCustomPackage, totalWeight: Double, customsForm: ShippingLabelCustomsForm?) {
        self.boxID = customPackage.title
        self.length = customPackage.getLength()
        self.width = customPackage.getWidth()
        self.height = customPackage.getHeight()
        self.weight = totalWeight
        self.isLetter = customPackage.isLetter
        self.customsForm = customsForm
    }

    public init(predefinedPackage: ShippingLabelPredefinedPackage, totalWeight: Double, customsForm: ShippingLabelCustomsForm?) {
        self.boxID = predefinedPackage.id
        self.length = predefinedPackage.getLength()
        self.width = predefinedPackage.getWidth()
        self.height = predefinedPackage.getHeight()
        self.weight = totalWeight
        self.isLetter = predefinedPackage.isLetter
        self.customsForm = customsForm
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

        let customsForm: ShippingLabelCustomsForm? = try? {
            let contentsType = try container.decode(ShippingLabelCustomsForm.ContentsType.self, forKey: .contentsType)
            let contentsExplanation = (try? container.decode(String.self, forKey: .contentsExplanation)) ?? ""
            let restrictionType = try container.decode(ShippingLabelCustomsForm.RestrictionType.self, forKey: .restrictionType)
            let restrictionComments = (try? container.decode(String.self, forKey: .restrictionComments)) ?? ""
            let nonDeliveryOption = try container.decode(ShippingLabelCustomsForm.NonDeliveryOption.self, forKey: .nonDeliveryOption)
            let itn = (try? container.decode(String.self, forKey: .itn)) ?? ""
            let items = try container.decode([ShippingLabelCustomsForm.Item].self, forKey: .items)

            return ShippingLabelCustomsForm(contentsType: contentsType,
                                            contentExplanation: contentsExplanation,
                                            restrictionType: restrictionType,
                                            restrictionComments: restrictionComments,
                                            nonDeliveryOption: nonDeliveryOption,
                                            itn: itn,
                                            items: items)
        }()

        self.init(boxID: boxID, length: length, width: width, height: height, weight: weight, isLetter: isLetter, customsForm: customsForm)
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
