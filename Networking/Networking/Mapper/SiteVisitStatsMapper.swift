import Foundation

/// Mapper: SiteVisitStats
///
class SiteVisitStatsMapper: Mapper {

    /// (Attempts) to convert a dictionary into an SiteVisitStats entity.
    ///
    func map(response: Data) throws -> SiteVisitStats {
        let decoder = JSONDecoder()
        return try decoder.decode(SiteVisitStats.self, from: response)
    }
}
