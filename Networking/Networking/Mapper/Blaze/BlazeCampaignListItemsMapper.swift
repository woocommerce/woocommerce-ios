import Foundation

/// Mapper: `BlazeCampaignListItem` List
///
struct BlazeCampaignListItemsMapper: Mapper {
    /// The site we're parsing `BlazeCampaignListItem`s for.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[BlazeCampaignListItem]`.
    ///
    func map(response: Data) throws -> [BlazeCampaignListItem] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.userInfo = [
            .siteID: siteID
        ]
        return try decoder.decode(BlazeCampaignListItemEnveloper.self, from: response).campaigns
    }
}


/// BlazeCampaignListItemEnveloper Disposable Entity.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct BlazeCampaignListItemEnveloper: Decodable {
    let campaigns: [BlazeCampaignListItem]
}
