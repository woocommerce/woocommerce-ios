import Foundation

/// Mapper: `BlazeCampaign` List
///
struct BlazeCampaignListMapper: Mapper {
    /// The site we're parsing `BlazeCampaign`s for.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[BlazeCampaign]`.
    ///
    func map(response: Data) throws -> [BlazeCampaign] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.userInfo = [
            .siteID: siteID
        ]
        return try decoder.decode(BlazeCampaignListEnvelope.self, from: response).campaigns
    }
}


/// BlazeCampaignListEnvelope Disposable Entity.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct BlazeCampaignListEnvelope: Decodable {
    let campaigns: [BlazeCampaign]
}
