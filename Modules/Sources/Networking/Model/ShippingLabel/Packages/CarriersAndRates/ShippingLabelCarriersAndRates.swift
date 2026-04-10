import Foundation

/// Represents the rate for all the Shipping Carriers
///
public struct ShippingLabelCarriersAndRates: Equatable {

    public var packageID: String?
    public let defaultRates: [ShippingLabelCarrierRate]
    public let signatureRequired: [ShippingLabelCarrierRate]
    public let adultSignatureRequired: [ShippingLabelCarrierRate]
    public let carbonNeutral: [ShippingLabelCarrierRate]
    public let saturdayDelivery: [ShippingLabelCarrierRate]
    public let additionalHandling: [ShippingLabelCarrierRate]

    public init(packageID: String?,
                defaultRates: [ShippingLabelCarrierRate],
                signatureRequired: [ShippingLabelCarrierRate],
                adultSignatureRequired: [ShippingLabelCarrierRate],
                carbonNeutral: [ShippingLabelCarrierRate],
                saturdayDelivery: [ShippingLabelCarrierRate],
                additionalHandling: [ShippingLabelCarrierRate]) {
        self.packageID = packageID
        self.defaultRates = defaultRates
        self.signatureRequired = signatureRequired
        self.adultSignatureRequired = adultSignatureRequired
        self.carbonNeutral = carbonNeutral
        self.saturdayDelivery = saturdayDelivery
        self.additionalHandling = additionalHandling
    }
}

// MARK: Codable
extension ShippingLabelCarriersAndRates: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let packageID = try container.decodeIfPresent(String.self, forKey: .packageID)
        let defaultRates = try container.decode(ShippingLabelRatesEnvelope.self, forKey: .defaultRates).rates
        let signatureRequired = try container.decode(ShippingLabelRatesEnvelope.self, forKey: .signatureRequired).rates
        let adultSignatureRequired = try container.decode(ShippingLabelRatesEnvelope.self, forKey: .adultSignatureRequired).rates
        let carbonNeutral = try container.decodeIfPresent(ShippingLabelRatesEnvelope.self, forKey: .carbonNeutral)?.rates ?? []
        let saturdayDelivery = try container.decodeIfPresent(ShippingLabelRatesEnvelope.self, forKey: .saturdayDelivery)?.rates ?? []
        let additionalHandling = try container.decodeIfPresent(ShippingLabelRatesEnvelope.self, forKey: .additionalHandling)?.rates ?? []

        self.init(packageID: packageID,
                  defaultRates: defaultRates,
                  signatureRequired: signatureRequired,
                  adultSignatureRequired: adultSignatureRequired,
                  carbonNeutral: carbonNeutral,
                  saturdayDelivery: saturdayDelivery,
                  additionalHandling: additionalHandling)
    }


    private enum CodingKeys: String, CodingKey {
        case packageID
        case defaultRates = "default"
        case signatureRequired
        case adultSignatureRequired
        case carbonNeutral
        case saturdayDelivery
        case additionalHandling
    }
}

private struct ShippingLabelRatesEnvelope: Decodable {
    let rates: [ShippingLabelCarrierRate]

    private enum CodingKeys: String, CodingKey {
        case rates
    }
}
