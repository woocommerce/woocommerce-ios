import Foundation


/// Mapper: OrderRefundCondensed
///
class OrderRefundCondensedMapper: Mapper {

    /// (Attempts) to convert a dictionary into a single OrderRefund
    ///
    func map(response: Data) throws -> OrderRefundCondensed {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        return try decoder.decode(OrderRefundEnvelope.self, from: response).orderRefundCondensed
    }
}


/// OrderRefundCondensed Disposable Entity:
/// `Add Order Refund` endpoint the single added refund within the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct OrderRefundEnvelope: Decodable {
    let orderRefundCondensed: OrderRefundCondensed

    private enum CodingKeys: String, CodingKey {
        case orderRefundCondensed = "data"
    }
}
