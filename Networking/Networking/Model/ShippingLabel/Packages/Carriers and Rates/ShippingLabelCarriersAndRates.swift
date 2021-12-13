import Foundation

/// Represents the rate for all the Shipping Carriers
///
public struct ShippingLabelCarriersAndRates: Equatable {

    public var packageID: String?
    public let defaultRates: [ShippingLabelCarrierRate]
    public let signatureRequired: [ShippingLabelCarrierRate]
    public let adultSignatureRequired: [ShippingLabelCarrierRate]

    public init(packageID: String?,
                defaultRates: [ShippingLabelCarrierRate],
                signatureRequired: [ShippingLabelCarrierRate],
                adultSignatureRequired: [ShippingLabelCarrierRate]) {
        self.packageID = packageID
        self.defaultRates = defaultRates
        self.signatureRequired = signatureRequired
        self.adultSignatureRequired = adultSignatureRequired
    }
}

// MARK: Codable
extension ShippingLabelCarriersAndRates: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let packageID = try container.decodeIfPresent(String.self, forKey: .packageID)
        let defaultRates = try container.decode(ShippingLabelRatesEnvelope.self, forKey: .defaultRates).rates
        let signatureRequired = try container.decode(ShippingLabelRatesEnvelope.self, forKey: .signatureRequired).rates
        let adultSignatureRequired = try container.decode(ShippingLabelRatesEnvelope.self, forKey: .adultSignatureRequired).rates


        self.init(packageID: packageID,
                  defaultRates: defaultRates,
                  signatureRequired: signatureRequired,
                  adultSignatureRequired: adultSignatureRequired)
    }


    private enum CodingKeys: String, CodingKey {
        case packageID
        case defaultRates = "default"
        case signatureRequired = "signature_required"
        case adultSignatureRequired = "adult_signature_required"
    }
}

private struct ShippingLabelRatesEnvelope: Decodable {
    let rates: [ShippingLabelCarrierRate]

    private enum CodingKeys: String, CodingKey {
        case rates
    }
}
