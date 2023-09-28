/// Mapper: Shipping Label Carriers and Rates Data
///
struct ShippingLabelCarriersAndRatesMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelCarriersAndRates array.
    ///
    func map(response: Data) throws -> [ShippingLabelCarriersAndRates] {
        let decoder = JSONDecoder()

        let container: ShippingLabelRatesEnvelope
        if hasDataEnvelope(in: response) {
            container = try decoder.decode(Envelope<ShippingLabelRatesEnvelope>.self, from: response).data
        } else {
            container = try decoder.decode(ShippingLabelRatesEnvelope.self, from: response)
        }

        return container.rates.boxes
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
