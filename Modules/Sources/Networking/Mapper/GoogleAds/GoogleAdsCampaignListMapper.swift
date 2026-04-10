import Foundation

/// Mapper: `[GoogleAdsCampaign]`
///
struct GoogleAdsCampaignListMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[GoogleAdsCampaign]`.
    ///
    func map(response: Data) throws -> [GoogleAdsCampaign] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(GoogleAdsCampaignListEnvelope.self, from: response).data
        } else {
            return try decoder.decode([GoogleAdsCampaign].self, from: response)
        }
    }
}


/// GoogleAdsCampaignListEnvelope Disposable Entity:
/// Load Google Ads campaign list endpoint returns the result in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct GoogleAdsCampaignListEnvelope: Decodable {
    let data: [GoogleAdsCampaign]
}
