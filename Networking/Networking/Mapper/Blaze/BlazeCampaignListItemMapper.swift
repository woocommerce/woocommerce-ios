import Foundation

/// Mapper: `BlazeCampaignListItem`
///
struct BlazeCampaignListItemMapper: Mapper {
    /// The site we're parsing `BlazeCampaignListItem` for.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `BlazeCampaignListItem`.
    ///
    func map(response: Data) throws -> BlazeCampaignListItem {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.userInfo = [
            .siteID: siteID
        ]
        return try decoder.decode(BlazeCampaignListItem.self, from: response)
    }
}
