import Foundation


/// Mapper: OrderStats
///
class OrderStatsMapper: Mapper {

    /// (Attempts) to convert a dictionary into [OrderStatItem].
    ///
    func map(response: Data) throws -> [OrderStatItem] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        return try decoder.decode(OrderStatsEnvelope.self, from: response).orderStats
    }
}


/// OrderStats Disposable Entity:
/// `Load Order Stats` endpoint returns all of its individual stat items within the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderStatsEnvelope: Decodable {
    let orderStats: [OrderStatItem]

    private enum CodingKeys: String, CodingKey {
        case orderStats = "data"
    }
}
