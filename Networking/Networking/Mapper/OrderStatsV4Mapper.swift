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
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
            .granularity: granularity
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<OrderStatsV4>.self, from: response).data
        } else {
            return try decoder.decode(OrderStatsV4.self, from: response)
        }
    }
}
