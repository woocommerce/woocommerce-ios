import Foundation


/// Mapper for an array of `OrderFulfillment` JSON objects.
///
struct OrderFulfillmentListMapper: Mapper {

    /// Site Identifier associated to the fulfillments that will be parsed.
    /// Injected via `JSONDecoder.userInfo` because the endpoint doesn't return siteID.
    ///
    let siteID: Int64

    /// Order Identifier associated to the fulfillments that will be parsed.
    /// Injected via `JSONDecoder.userInfo` because the endpoint doesn't return orderID.
    ///
    let orderID: Int64

    /// (Attempts) to convert a dictionary into [OrderFulfillment].
    ///
    /// Handles both:
    /// - Bare array response: `[{ ... }, { ... }]`
    /// - Envelope response: `{ "fulfillments": [{ ... }, { ... }] }`
    ///
    func map(response: Data) throws -> [OrderFulfillment] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Stats.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        // Try envelope first, then bare array
        if let envelope = try? decoder.decode(OrderFulfillmentListEnvelope.self, from: response) {
            return envelope.fulfillments
        }

        if hasDataEnvelope(in: response) {
            return try decoder.decode(OrderFulfillmentDataEnvelope.self, from: response).fulfillments
        }

        return try decoder.decode([OrderFulfillment].self, from: response)
    }
}


/// Envelope for when the API wraps fulfillments in a "fulfillments" key.
///
private struct OrderFulfillmentListEnvelope: Decodable {
    let fulfillments: [OrderFulfillment]

    private enum CodingKeys: String, CodingKey {
        case fulfillments
    }
}


/// Envelope for when the API wraps fulfillments in a "data" key.
///
private struct OrderFulfillmentDataEnvelope: Decodable {
    let fulfillments: [OrderFulfillment]

    private enum CodingKeys: String, CodingKey {
        case fulfillments = "data"
    }
}
