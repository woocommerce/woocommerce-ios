import Foundation


/// Mapper: SiteVisitStats
///
struct SiteVisitStatsMapper: Mapper {

    /// Local query Identifier associated to the order stats that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because we need to display different type of stats.
    ///
    let queryID: String

    /// (Attempts) to convert a dictionary into an SiteVisitStats entity.
    ///
    func map(response: Data) throws -> SiteVisitStats {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .queryID: queryID
        ]
        return try decoder.decode(SiteVisitStats.self, from: response)
    }
}
