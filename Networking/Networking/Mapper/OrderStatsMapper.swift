import Foundation

/// Mapper: OrderStats
///
class OrderStatsMapper: Mapper {

    /// (Attempts) to convert a dictionary into an OrderStats entity.
    ///
    func map(response: Data) throws -> OrderStats {
        let decoder = JSONDecoder()
        return try decoder.decode(OrderStats.self, from: response)
    }
}
