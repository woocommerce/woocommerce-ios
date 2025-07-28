import Foundation

/// Mapper: `BlazeAISuggestion`
///
struct BlazeAISuggestionListMapper: Mapper {
    /// (Attempts) to convert a list of dictionary into `[BlazeAISuggestion]`.
    ///
    func map(response: Data) throws -> [BlazeAISuggestion] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(BlazeAISuggestionsEnvelope.self, from: response).creatives
    }
}

private struct BlazeAISuggestionsEnvelope: Decodable {
    let creatives: [BlazeAISuggestion]
}
