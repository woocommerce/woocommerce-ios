import Foundation

/// Mapper: `AIProduct` generated using AI
///
struct AIProductMapper: Mapper {
    let siteID: Int64

    func map(response: Data) throws -> AIProduct {
        let decoder = JSONDecoder()
        let textCompletion = try decoder.decode(JetpackAIQueryResponse.self, from: response).aiResponse()
            // OpenAI sometimes returns the JSON response wrapped in a code block Markdown syntax, we remove it
            // see: https://community.openai.com/t/why-do-some-responses-message-content-start-with-json/573289
            .removingPrefix("```json")
            .removingSuffix("```")
        return try decoder.decode(AIProduct.self, from: Data(textCompletion.utf8))
    }

    func map(dictionary: [String: Any]) throws -> AIProduct {
        // For non-network requests we pass [String: Any] to the map() as data, however decoding
        // relies on mapping to a JetpackAIQueryResponse model, which fails in the direct API usage key
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try decoder.decode(AIProduct.self, from: data)
    }
}
