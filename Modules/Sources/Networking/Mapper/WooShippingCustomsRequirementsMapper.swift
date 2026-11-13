import Foundation

/// Mapper for WooShipping customs requirements.
struct WooShippingCustomsRequirementsMapper: Mapper {
    func map(response: Data) throws -> Bool {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingCustomsRequirementsMapperEnvelope.self, from: response).data.euProductIDsRequired
        } else {
            return try decoder.decode(WooShippingCustomsRequirements.self, from: response).euProductIDsRequired
        }
    }
}

private struct WooShippingCustomsRequirementsMapperEnvelope: Decodable {
    let data: WooShippingCustomsRequirements
}

private struct WooShippingCustomsRequirements: Decodable {
    let euProductIDsRequired: Bool

    private enum CodingKeys: String, CodingKey {
        case euProductIDsRequired = "eu_product_ids_required"
    }
}
