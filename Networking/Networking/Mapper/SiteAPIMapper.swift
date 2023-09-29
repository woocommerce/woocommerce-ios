/// Mapper: SiteAPI
///
struct SiteAPIMapper: Mapper {

    /// Site Identifier associated to the API information that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [SiteSetting].
    ///
    func map(response: Data) throws -> SiteAPI {
        try extract(
            from: response,
            siteID: siteID,
            dateFormatter: DateFormatter.Defaults.dateTimeFormatter
        )
    }
}
