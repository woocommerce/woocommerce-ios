import Foundation

/// Mapper for product identifiers in WooShipping config line items.
struct WooShippingEUProductIdentifiersMapper: Mapper {
    static let fieldsToLoad = "config.order.line_items"

    func map(response: Data) throws -> [WooShippingEUProductIdentifiers] {
        let decoder = JSONDecoder()
        let configResponse: WooShippingEUProductIdentifiersMapperResponse
        if hasDataEnvelope(in: response) {
            configResponse = try decoder.decode(WooShippingEUProductIdentifiersMapperEnvelope.self, from: response).data
        } else {
            configResponse = try decoder.decode(WooShippingEUProductIdentifiersMapperResponse.self, from: response)
        }
        return configResponse.config?.order?.lineItems ?? []
    }
}

private struct WooShippingEUProductIdentifiersMapperResponse: Decodable {
    let config: Config?

    struct Config: Decodable {
        let order: Order?
    }

    struct Order: Decodable {
        let lineItems: [WooShippingEUProductIdentifiers]?

        private enum CodingKeys: String, CodingKey {
            case lineItems = "line_items"
        }
    }
}

private struct WooShippingEUProductIdentifiersMapperEnvelope: Decodable {
    let data: WooShippingEUProductIdentifiersMapperResponse
}
