import Foundation

/// Mapper: `[BlazeCampaignObjective]`
///
struct BlazeCampaignObjectiveListMapper: Mapper {
    /// Locale of the response.
    let locale: String

    /// (Attempts) to convert a list of dictionary into `[BlazeCampaignObjective]`.
    ///
    func map(response: Data) throws -> [BlazeCampaignObjective] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.userInfo = [
            .locale: locale
        ]
        return try decoder.decode(BlazeCampaignObjectiveListEnvelope.self, from: response).objectives
    }
}

private struct BlazeCampaignObjectiveListEnvelope: Decodable {
    let objectives: [BlazeCampaignObjective]
}
