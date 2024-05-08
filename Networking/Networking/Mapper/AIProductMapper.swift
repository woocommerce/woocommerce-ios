#if os(iOS)

import Foundation

/// Mapper: `AIProduct` generated using AI
///
struct AIProductMapper: Mapper {
    let siteID: Int64

    func map(response: Data) throws -> AIProduct {
        let decoder = JSONDecoder()
        let textCompletion = try decoder.decode(TextCompletionResponse.self, from: response).completion
        return try decoder.decode(AIProduct.self, from: Data(textCompletion.utf8))
    }
}

private struct TextCompletionResponse: Decodable {
    let completion: String
}

#endif
