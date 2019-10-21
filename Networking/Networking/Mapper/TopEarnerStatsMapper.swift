import Foundation

/// Mapper: TopEarnerStats
///
class TopEarnerStatsMapper: Mapper {

    /// (Attempts) to convert a dictionary into an TopEarnerStats entity.
    ///
    func map(response: Data) throws -> TopEarnerStats {
        let decoder = JSONDecoder()
        return try decoder.decode(TopEarnerStats.self, from: response)
    }
}
