import Foundation


/// Mapper: TopEarnerStats
///
struct TopEarnerStatsMapper: Mapper {
    /// Site Identifier associated to the stats that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// really return the siteID for the stats endpoint
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into an TopEarnerStats entity.
    ///
    func map(response: Data) throws -> TopEarnerStats {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
        ]
        return try decoder.decode(TopEarnerStats.self, from: response)
    }
}
