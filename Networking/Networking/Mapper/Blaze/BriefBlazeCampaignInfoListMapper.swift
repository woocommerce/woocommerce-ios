import Foundation

/// Mapper: `BriefBlazeCampaignInfo` List
///
struct BriefBlazeCampaignInfoListMapper: Mapper {
    /// The site we're parsing `BriefBlazeCampaignInfo`s for.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[BriefBlazeCampaignInfo]`.
    ///
    func map(response: Data) throws -> [BriefBlazeCampaignInfo] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.userInfo = [
            .siteID: siteID
        ]
        return try decoder.decode(BriefBlazeCampaignInfoListEnvelope.self, from: response).campaigns
    }
}


/// BriefBlazeCampaignInfoListEnvelope Disposable Entity.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct BriefBlazeCampaignInfoListEnvelope: Decodable {
    let campaigns: [BriefBlazeCampaignInfo]
}
