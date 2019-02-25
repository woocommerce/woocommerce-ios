import Foundation


/// Mapper: OrderStatus
///
class OrderStatusMapper: Mapper {

    /// (Attempts) to convert a dictionary into an OrderStatus entity.
    ///
    func map(response: Data) throws -> [OrderStatus] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        return try decoder.decode(OrderStatusEnvelope.self, from: response).orderStatus
    }
}

/// OrderStatusEnvelope Disposable Entity:
/// `OrderStatus` endpoint returns a list of all order statuses in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct OrderStatusEnvelope: Decodable {
    let orderStatus: [OrderStatus]

    private enum CodingKeys: String, CodingKey {
        case orderStatus = "data"
    }
}
