/// Mapper: WCAnalyticsCustomer
///
struct WCAnalyticsCustomerMapper: Mapper {
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Customer endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into a `[WCAnalyticsCustomer]` entity
    ///
    func map(response: Data) throws -> [WCAnalyticsCustomer] {
        return try extract(
            from: response,
            siteID: siteID,
            dateFormatter: DateFormatter.Defaults.dateTimeFormatter
        )
    }
}
