import Foundation

/// Mapper: Create Blaze Campaign request
///
struct CreateBlazeCampaignMapper: Mapper {

    /// (Attempts) to parse the create Blaze campaign response
    ///
    func map(response: Data) throws -> Void {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        _ = try decoder.decode(CreateBlazeCampaignResponse.self, from: response)
    }
}

private struct CreateBlazeCampaignResponse: Decodable {
    public let id: String
}
