import Foundation
import Codegen

/// Represents the complete package details that will be sent to the Woo Shipping Purchase endpoint.
///
public struct WooShippingPackagePurchase: Equatable, GeneratedFakeable, GeneratedCopiable {

    /// ID for the shipment being sent in this package, e.g. `shipment_0`
    public let shipmentID: String

    /// Selected package for the shipping label
    public let package: ShippingLabelPackageSelected

    /// Selected rate for the shipping label
    public let selectedRate: WooShippingSelectedRate

    /// IDs for the products to be shipped
    public let productIDs: [Int64]

    public init(shipmentID: String,
                package: ShippingLabelPackageSelected,
                selectedRate: WooShippingSelectedRate,
                productIDs: [Int64]) {
        self.shipmentID = shipmentID
        self.package = package
        self.selectedRate = selectedRate
        self.productIDs = productIDs
    }
}

// MARK: Helpers

extension WooShippingPackagePurchase {

    var rate: ShippingLabelCarrierRate {
        selectedRate.purchaseRate
    }

    var selectedRateOptions: [String: Any] {
        var rates: [String: Any] = [:]
        if selectedRate.signatureRate != nil {
            rates[CodingKeys.signature.rawValue] = [
                ParameterKeys.value: Values.yes,
                ParameterKeys.surcharge: selectedRate.surchargeForSignatureRequirement
            ]
        } else if selectedRate.adultSignatureRate != nil {
            rates[CodingKeys.signature.rawValue] = [
                ParameterKeys.value: Values.adult,
                ParameterKeys.surcharge: selectedRate.surchargeForAdultSignatureRequirement
            ]
        }

        if selectedRate.carbonNeutralRate != nil {
            rates[CodingKeys.carbonNeutral.rawValue] = [
                ParameterKeys.value: true,
                ParameterKeys.surcharge: selectedRate.surchargeForCarbonNeutralRate
            ]
        }

        if selectedRate.saturdayDeliveryRate != nil {
            rates[CodingKeys.saturdayDelivery.rawValue] = [
                ParameterKeys.value: true,
                ParameterKeys.surcharge: selectedRate.surchargeForSaturdayDeliveryRate
            ]
        }

        if selectedRate.additionalHandlingRate != nil {
            rates[CodingKeys.additionalHandling.rawValue] = [
                ParameterKeys.value: true,
                ParameterKeys.surcharge: selectedRate.surchargeForAdditionalHandlingRate
            ]
        }

        return rates
    }
}

// MARK: Enodable

extension WooShippingPackagePurchase: Encodable {

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
        try container.encode(productIDs, forKey: .products)

        if selectedRate.signatureRate != nil {
            try container.encode(Values.yes, forKey: .signature)
        } else if selectedRate.adultSignatureRate != nil {
            try container.encode(Values.adult, forKey: .signature)
        }

        if selectedRate.carbonNeutralRate != nil {
            try container.encode(true, forKey: .carbonNeutral)
        }

        if selectedRate.saturdayDeliveryRate != nil {
            try container.encode(true, forKey: .saturdayDelivery)
        }

        if selectedRate.additionalHandlingRate != nil {
            try container.encode(true, forKey: .additionalHandling)
        }
    }

    /// Converts the shipment rate to a dictionary as the API expects it.
    /// Includes the shipment ID with the encoded rate.
    ///
    public func encodedShipmentRate() throws -> [String: Any] {
        [shipmentID: [ParameterKeys.rate: try rate.toDictionary()]]
    }

    /// Converts the hazmat settings to a dictionary as the API expects it.
    /// Includes the shipment ID if there are hazmat settings to report.
    public func encodedHazmat() -> [String: Any] {
        [shipmentID: [
            ParameterKeys.isHazmat: package.hazmatCategory != nil,
            ParameterKeys.category: package.hazmatCategory ?? String()
        ]]
    }

    /// Converts the customs form to a dictionary as the API expects it.
    /// Includes the shipment ID with the encoded customs form.
    public func encodedCustomsForm() throws -> [String: Any] {
        guard let form = package.customsForm else {
            return [shipmentID: [:]]
        }
        return [shipmentID: [
            ParameterKeys.items: try form.items.map { try $0.toDictionary() },
            ParameterKeys.contentsType: form.contentsType.rawValue,
            ParameterKeys.contentsExplanation: form.contentExplanation,
            ParameterKeys.restrictionType: form.restrictionType.rawValue,
            ParameterKeys.restrictionComments: form.restrictionComments,
            ParameterKeys.isReturnToSender: form.nonDeliveryOption == .return,
            ParameterKeys.itn: form.itn
        ]]
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
        case signature
        case carbonNeutral = "carbon_neutral"
        case saturdayDelivery = "saturday_delivery"
        case additionalHandling = "additional_handling"
    }

    private enum ParameterKeys {
        static let rate = "rate"
        static let isHazmat = "isHazmat"
        static let category = "category"
        static let contentsType = "contentsType"
        static let contentsExplanation = "contentsExplanation"
        static let restrictionType = "restrictionType"
        static let restrictionComments = "restrictionComments"
        static let isReturnToSender = "isReturnToSender"
        static let itn = "itn"
        static let items = "items"
        static let value = "value"
        static let surcharge = "surcharge"
    }

    private enum Values {
        static let yes = "yes"
        static let adult = "adult"
    }
}
