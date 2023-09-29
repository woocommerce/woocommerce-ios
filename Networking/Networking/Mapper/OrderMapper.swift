struct OrderMapper: Mapper {

    /// Site Identifier associated to the order that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [Order].
    ///
    func map(response: Data) throws -> Order {
        try extract(
            from: response,
            siteID: siteID,
            dateFormatter: DateFormatter.Defaults.dateTimeFormatter
        )
    }
}
