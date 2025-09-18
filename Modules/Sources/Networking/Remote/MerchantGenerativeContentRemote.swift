import Foundation

/// Generative content remote that uses merchant's API key for OpenAI instead of Jetpack AI
///
public final class MerchantGenerativeContentRemote: GenerativeContentRemoteProtocol {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func generateText(siteID: Int64,
                             base: String,
                             feature: GenerativeContentRemoteFeature,
                             responseFormat: GenerativeContentRemoteResponseFormat) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "user",
                    "content": base
                ]
            ],
            "max_tokens": 1000,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw MerchantGenerativeContentRemoteError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func identifyLanguage(siteID: Int64,
                                 string: String,
                                 feature: GenerativeContentRemoteFeature) async throws -> String {
        let prompt = String(format: AIRequestPrompts.identifyLanguage, string)
        return try await generateText(siteID: siteID, base: prompt, feature: feature, responseFormat: .text)
    }

    public func generateAIProduct(siteID: Int64,
                                  productName: String?,
                                  keywords: String,
                                  language: String,
                                  tone: String,
                                  currencySymbol: String,
                                  dimensionUnit: String?,
                                  weightUnit: String?,
                                  categories: [ProductCategory],
                                  tags: [ProductTag]) async throws -> AIProduct {
        // For now throw an error
        throw MerchantGenerativeContentRemoteError.notImplemented
    }
}

private enum MerchantGenerativeContentRemoteError: Error {
    case notImplemented
    case invalidResponse
}
