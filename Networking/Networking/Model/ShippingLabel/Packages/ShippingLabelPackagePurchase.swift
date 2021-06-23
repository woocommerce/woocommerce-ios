import Foundation
import Codegen

/// Represents the complete package details that will be sent to the Shipping Labels Purchase endpoint.
///
public struct ShippingLabelPackagePurchase: Equatable, GeneratedFakeable {

    /// Selected package for the shipping label
    public let package: ShippingLabelPackageSelected

    /// Selected rate for the shipping label
    public let rate: ShippingLabelCarrierRate

    /// IDs for the products to be shipped
    public let products: [Int64]

    public init(package: ShippingLabelPackageSelected, rate: ShippingLabelCarrierRate, products: [Int64]) {
        self.package = package
        self.rate = rate
        self.products = products
    }
}

// MARK: Codable
extension ShippingLabelPackagePurchase: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(package.id, forKey: .id)
        try container.encode(package.boxID, forKey: .boxID)
        try container.encode(package.length, forKey: .length)
        try container.encode(package.width, forKey: .width)
        try container.encode(package.height, forKey: .height)
        try container.encode(package.weight, forKey: .weight)
        try container.encode(package.isLetter, forKey: .isLetter)
        try container.encode(rate.shipmentID, forKey: .shipmentID)
        try container.encode(rate.rateID, forKey: .rateID)
        try container.encode(rate.serviceID, forKey: .serviceID)
        try container.encode(rate.carrierID, forKey: .carrierID)
        try container.encode(rate.title, forKey: .serviceName)
        try container.encode(products, forKey: .products)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case boxID = "box_id"
        case length
        case width
        case height
        case weight
        case isLetter = "is_letter"
        case shipmentID = "shipment_id"
        case rateID = "rate_id"
        case serviceID = "service_id"
        case carrierID = "carrier_id"
        case serviceName = "service_name"
        case products
    }
}
