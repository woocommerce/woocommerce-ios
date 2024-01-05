import Foundation

/// Mapper: Create Blaze Campaign request
///
struct CreateBlazeCampaignMapper: Mapper {

    /// (Attempts) to parse the create Blaze campaign response
    ///
    func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CreateBlazeCampaignResponse.self, from: response).id
    }
}

private struct CreateBlazeCampaignResponse: Decodable {
    public let id: Int64
}
