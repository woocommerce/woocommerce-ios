import Foundation


/// Mapper: WooShipping Label Rates Data
///
struct WooShippingLabelRatesMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelCarriersAndRates array.
    ///
    func map(response: Data) throws -> [ShippingLabelCarriersAndRates] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ShippingLabelDataEnvelope.self, from: response).data.boxes
        } else {
            return try decoder.decode(ShippingLabelDefaultBoxEnvelope.self, from: response).boxes
        }
    }
}

/// ShippingLabelDataEnvelope Disposable Entity:
/// `Carriers and Rates Shipping Label` endpoint returns the shipping label document under `data` -> `default_box`  key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ShippingLabelDataEnvelope: Decodable {
    let data: ShippingLabelDefaultBoxEnvelope

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

private struct ShippingLabelDefaultBoxEnvelope: Decodable {
    let boxes: [ShippingLabelCarriersAndRates]

    init(from decoder: Decoder) throws {

        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: ShippingLabelCarriersAndRates].self)

        boxes = dictionary.map { key, value in
            return ShippingLabelCarriersAndRates(packageID: key,
                                                 defaultRates: value.defaultRates,
                                                 defaultErrors: value.defaultErrors,
                                                 signatureRequired: value.signatureRequired,
                                                 adultSignatureRequired: value.adultSignatureRequired,
                                                 carbonNeutral: value.carbonNeutral,
                                                 saturdayDelivery: value.saturdayDelivery,
                                                 additionalHandling: value.additionalHandling)
        }
    }
}
