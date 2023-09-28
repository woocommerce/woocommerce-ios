/// Mapper: `Subscription` List
///
struct SubscriptionListMapper: Mapper {
    /// Site we're parsing `Subscription`s for
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Subscription endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[Subscription]`.
    ///
    func map(response: Data) throws -> [Subscription] {
        try extract(
            from: response,
            usingJSONDecoderSiteID: siteID,
            dateFormatter: DateFormatter.Defaults.dateTimeFormatter
        )
    }
}
