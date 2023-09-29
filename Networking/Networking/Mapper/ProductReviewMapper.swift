struct ProductReviewMapper: Mapper {

    /// Site Identifier associated to the product review that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into ProductReview.
    ///
    func map(response: Data) throws -> ProductReview {
        try extract(
            from: response,
            siteID: siteID,
            dateFormatter: DateFormatter.Defaults.dateTimeFormatter
        )
    }
}
