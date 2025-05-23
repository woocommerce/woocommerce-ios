import Foundation

/// Mapper: GoogleAdsCampaignStats
///
struct GoogleAdsCampaignStatsMapper: Mapper {
    /// Site Identifier associated with the stats that will be parsed.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into a StatsReport entity.
    ///
    func map(response: Data) throws -> GoogleAdsCampaignStats {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(GoogleAdsCampaignStatsEnvelope.self, from: response).data
        } else {
            return try decoder.decode(GoogleAdsCampaignStats.self, from: response)
        }
    }
}


/// GoogleAdsCampaignStatsEnvelope Disposable Entity
///
/// Stats endpoint returns the requested stats in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct GoogleAdsCampaignStatsEnvelope: Decodable {
    let data: GoogleAdsCampaignStats
}
