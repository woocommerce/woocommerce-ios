import Foundation


/// Mapper: ProductBundleStats
///
struct ProductBundleStatsMapper: Mapper {
    /// Site Identifier associated to the stats that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// really return the siteID for the stats v4 endpoint
    ///
    let siteID: Int64

    /// Granularity associated to the stats that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// really return the granularity for the stats v4 endpoint
    ///
    let granularity: StatsGranularityV4

    /// (Attempts) to convert a dictionary into a StatsReport entity.
    ///
    func map(response: Data) throws -> ProductBundleStats {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
            .granularity: granularity
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductBundleStatsEnvelope.self, from: response).bundleStats
        } else {
            return try decoder.decode(ProductBundleStats.self, from: response)
        }
    }
}


/// StatsReportEnvelope Disposable Entity
///
/// Stats endpoint returns the requested stats in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ProductBundleStatsEnvelope: Decodable {
    let bundleStats: ProductBundleStats

    private enum CodingKeys: String, CodingKey {
        case bundleStats = "data"
    }
}
