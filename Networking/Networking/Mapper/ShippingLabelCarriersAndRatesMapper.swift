import Foundation


/// Mapper: Shipping Label Carriers and Rates Data
///
struct ShippingLabelCarriersAndRatesMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelCarriersAndRates array.
    ///
    func map(response: Data) throws -> [ShippingLabelCarriersAndRates] {
        let decoder = JSONDecoder()
        return try decoder.decode(ShippingLabelDataEnvelope.self, from: response).data.rates.boxes
    }
}

/// ShippingLabelDataEnvelope Disposable Entity:
/// `Carriers and Rates Shipping Label` endpoint returns the shipping label document under `data` -> `rates` -> `default_box`  key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ShippingLabelDataEnvelope: Decodable {
    let data: ShippingLabelRatesEnvelope

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

private struct ShippingLabelRatesEnvelope: Decodable {
    let rates: ShippingLabelDefaultBoxEnvelope

    private enum CodingKeys: String, CodingKey {
        case rates
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
                                                 signatureRequired: value.signatureRequired,
                                                 adultSignatureRequired: value.adultSignatureRequired)
        }
    }
}
