import Foundation

struct ShippingScaleStatusMapper: Mapper {

    /// (Attempts) to convert a dictionary into scale data.
    ///
    func map(response: Data) throws -> ShippingScaleStatus {
        let decoder = JSONDecoder()

        return try decoder.decode(ShippingScaleEnvelope.self, from: response).data
    }
}

private struct ShippingScaleEnvelope: Decodable {
    let data: ShippingScaleStatus

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
