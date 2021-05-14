import Foundation


/// Mapper: Shipping Label Carriers and Rates Data
///
struct ShippingLabelCarriersAndRatesMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelCarriersAndRates.
    ///
    func map(response: Data) throws -> ShippingLabelCarriersAndRates {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        return try decoder.decode(ShippingLabelDataEnvelope.self, from: response).data.rates.defaultBox
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
    let defaultBox: ShippingLabelCarriersAndRates

    private enum CodingKeys: String, CodingKey {
        case defaultBox = "default_box"
    }
}
