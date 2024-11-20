import Foundation
import Codegen

/// Represents the rate for a specific shipping carrier
///
public struct ShippingLabelCarrierRate: Equatable, GeneratedFakeable {

    public let title: String
    public let insurance: String
    public let retailRate: Double
    public let rate: Double
    public let rateID: String
    public let serviceID: String
    public let carrierID: String
    public let shipmentID: String
    public let hasTracking: Bool
    public let isSelected: Bool
    public let isPickupFree: Bool
    public let deliveryDays: Int64?
    public let deliveryDateGuaranteed: Bool

    public init(title: String,
                insurance: String,
                retailRate: Double,
                rate: Double,
                rateID: String,
                serviceID: String,
                carrierID: String,
                shipmentID: String,
                hasTracking: Bool,
                isSelected: Bool,
                isPickupFree: Bool,
                deliveryDays: Int64?,
                deliveryDateGuaranteed: Bool) {
        self.title = title
        self.insurance = insurance
        self.retailRate = retailRate
        self.rate = rate
        self.rateID = rateID
        self.serviceID = serviceID
        self.carrierID = carrierID
        self.shipmentID = shipmentID
        self.hasTracking = hasTracking
        self.isSelected = isSelected
        self.isPickupFree = isPickupFree
        self.deliveryDays = deliveryDays
        self.deliveryDateGuaranteed = deliveryDateGuaranteed
    }
}

// MARK: Codable
extension ShippingLabelCarrierRate: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let title = try container.decode(String.self, forKey: .title)

        let insurance: String
        if let insuranceAmount = try? container.decode(Double.self, forKey: .insurance) {
            insurance = String(insuranceAmount)
        } else {
            insurance = try container.decode(String.self, forKey: .insurance)
        }

        let retailRate = try container.decode(Double.self, forKey: .retailRate)
        let rate = try container.decode(Double.self, forKey: .rate)
        let rateID = try container.decode(String.self, forKey: .rateId)
        let serviceID = try container.decode(String.self, forKey: .serviceId)
        let carrierID = try container.decode(String.self, forKey: .carrierId)
        let shipmentID = try container.decode(String.self, forKey: .shipmentId)
        let hasTracking = try container.decode(Bool.self, forKey: .tracking)
        let isSelected = try container.decode(Bool.self, forKey: .isSelected)
        let isPickupFree = try container.decode(Bool.self, forKey: .freePickup)
        let deliveryDays = try container.decodeIfPresent(Int64.self, forKey: .deliveryDays)
        let deliveryDateGuaranteed = try container.decode(Bool.self, forKey: .deliveryDateGuaranteed)


        self.init(title: title,
                  insurance: insurance,
                  retailRate: retailRate,
                  rate: rate,
                  rateID: rateID,
                  serviceID: serviceID,
                  carrierID: carrierID,
                  shipmentID: shipmentID,
                  hasTracking: hasTracking,
                  isSelected: isSelected,
                  isPickupFree: isPickupFree,
                  deliveryDays: deliveryDays,
                  deliveryDateGuaranteed: deliveryDateGuaranteed)
    }


    private enum CodingKeys: String, CodingKey {
        case title
        case insurance
        case retailRate
        case rate
        case rateId
        case serviceId
        case carrierId
        case shipmentId
        case tracking
        case isSelected
        case freePickup
        case deliveryDays
        case deliveryDateGuaranteed
    }
}
