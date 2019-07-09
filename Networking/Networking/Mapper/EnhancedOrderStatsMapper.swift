import Foundation


/// Mapper: OrderStats
///
struct OrderStatsV4Mapper: Mapper {

    /// (Attempts) to convert a dictionary into an OrderStats entity.
    ///
    func map(response: Data) throws -> OrderStatsV4 {
        let decoder = JSONDecoder()
        return try decoder.decode(OrderStatsV4Envelope.self, from: response).orderStats
    }
}


/// OrderStatsV4Envelope Disposable Entity
///
/// `Load Order` endpoint returns the requested order document in the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderStatsV4Envelope: Decodable {
    let orderStats: OrderStatsV4

    private enum CodingKeys: String, CodingKey {
        case orderStats = "data"
    }
}
