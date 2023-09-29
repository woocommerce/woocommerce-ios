/// Mapper: OrderStats
///
struct OrderStatsV4Mapper: Mapper {
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

    /// (Attempts) to convert a dictionary into an OrderStats entity.
    ///
    func map(response: Data) throws -> OrderStatsV4 {
        try extract(
            from: response,
            decodingUserInfo: [.siteID: siteID, .granularity: granularity]
        )
    }
}
