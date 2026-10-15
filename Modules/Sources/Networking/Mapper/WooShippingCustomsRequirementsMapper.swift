import Foundation

/// Mapper for WooShipping customs requirements.
struct WooShippingCustomsRequirementsMapper: Mapper {
    func map(response: Data) throws -> WooShippingCustomsRequirements {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingCustomsRequirementsMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode(WooShippingCustomsRequirements.self, from: response)
        }
    }
}

private struct WooShippingCustomsRequirementsMapperEnvelope: Decodable {
    let data: WooShippingCustomsRequirements
}
