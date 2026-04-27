import Foundation

/// Mapper: `SupportChatResponse` returned by the `/wpcom/v2/odie/chat/{bot_slug}` endpoint.
///
struct SupportChatResponseMapper: Mapper {
    func map(response: Data) throws -> SupportChatResponse {
        try JSONDecoder().decode(SupportChatResponse.self, from: response)
    }
}
