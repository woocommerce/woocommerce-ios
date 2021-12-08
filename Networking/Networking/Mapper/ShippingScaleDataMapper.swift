import Foundation

struct ShippingScaleDataMapper: Mapper {

    /// (Attempts) to convert a dictionary into scale data.
    ///
    func map(response: Data) throws -> ShippingScaleData {
        let decoder = JSONDecoder()

        return try decoder.decode(ShippingScaleEnvelope.self, from: response).data
    }
}

private struct ShippingScaleEnvelope: Decodable {
    let data: ShippingScaleData

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
