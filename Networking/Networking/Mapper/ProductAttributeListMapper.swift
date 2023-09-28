typealias ProductAttributeListMapper = GenericMapper<[ProductAttribute]>

struct GenericMapper<Resource: Decodable>: Mapper {

    /// Site Identifier associated to the `Resource`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the endpoints.
    let siteID: Int64

    func map(response: Data) throws -> Resource {
        try extract(
            from: response,
            usingJSONDecoderSiteID: siteID,
            dateFormatter: DateFormatter.Defaults.dateTimeFormatter
        )
    }
}
