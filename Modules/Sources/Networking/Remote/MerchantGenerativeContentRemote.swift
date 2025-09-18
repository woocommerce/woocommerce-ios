import Foundation
import NetworkingCore

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
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
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

        // Build input components
        var inputComponents = [String(format: AIRequestPrompts.inputComponents, keywords, tone)]

        // Name will be added only if `productName` is available
        if let productName = productName, !productName.isEmpty {
            inputComponents.insert(String(format: AIRequestPrompts.productNameTemplate, productName), at: 1)
        }

        let input = inputComponents.joined(separator: "\n")

        // Build JSON response format dictionary
        let jsonResponseFormatDict: [String: Any] = {
            let tagsPrompt: String = {
                guard !tags.isEmpty else {
                    return AIRequestPrompts.defaultTagsPrompt
                }
                return String(format: AIRequestPrompts.existingTagsPrompt, tags.map { $0.name }.joined(separator: ", "))
            }()

            let categoriesPrompt: String = {
                guard !categories.isEmpty else {
                    return AIRequestPrompts.defaultCategoriesPrompt
                }
                return String(format: AIRequestPrompts.existingCategoriesPrompt, categories.map { $0.name }.joined(separator: ", "))
            }()

            let shippingPrompt = {
                var dict = [String: String]()
                if let weightUnit {
                    dict["weight"] = String(format: AIRequestPrompts.weightPrompt, weightUnit)
                }

                if let dimensionUnit {
                    dict["length"] = String(format: AIRequestPrompts.lengthPrompt, dimensionUnit)
                    dict["width"] = String(format: AIRequestPrompts.widthPrompt, dimensionUnit)
                    dict["height"] = String(format: AIRequestPrompts.heightPrompt, dimensionUnit)
                }
                return dict
            }()

            return ["names": String(format: AIRequestPrompts.namesFormat, language),
                    "descriptions": String(format: AIRequestPrompts.descriptionsFormat, tone, language),
                    "short_descriptions": String(format: AIRequestPrompts.shortDescriptionsFormat, tone, language),
                    "virtual": AIRequestPrompts.virtualFormat,
                    "shipping": shippingPrompt,
                    "price": String(format: AIRequestPrompts.priceFormat, currencySymbol),
                    "tags": tagsPrompt,
                    "categories": categoriesPrompt]
        }()

        let expectedJsonFormat = String(format: AIRequestPrompts.jsonFormatInstructions,
                                        jsonResponseFormatDict.toJSONEncoded() ?? "")

        let prompt = input + "\n" + expectedJsonFormat

        // Make OpenAI API request
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw MerchantGenerativeContentRemoteError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            // gpt-4 does not support response_format parameter with json_object type, which does work with gpt-3 and the Jetpack tunnel
            // This may change further based on the selected model, and the AI provider, so has to be handled here.
            // ie:
            // "response_format": ["type": "json_object"],
            "max_tokens": 4000,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)

        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse OpenAI response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw MerchantGenerativeContentRemoteError.invalidResponse
        }

        // Parse the AI-generated product JSON
        guard let contentData = content.data(using: .utf8),
              let productJson = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            throw MerchantGenerativeContentRemoteError.invalidResponse
        }

        // Extract and create AIProduct manually
        let names = productJson["names"] as? [String] ?? []
        let descriptions = productJson["descriptions"] as? [String] ?? []
        let shortDescriptions = productJson["short_descriptions"] as? [String] ?? []
        let virtual = productJson["virtual"] as? Bool ?? false
        let price = productJson["price"] as? String ?? ""
        let aiTags = productJson["tags"] as? [String] ?? []
        let aiCategories = productJson["categories"] as? [String] ?? []

        // Extract shipping info
        let shippingDict = productJson["shipping"] as? [String: Any] ?? [:]
        let length = shippingDict["length"] as? String ?? ""
        let weight = shippingDict["weight"] as? String ?? ""
        let width = shippingDict["width"] as? String ?? ""
        let height = shippingDict["height"] as? String ?? ""

        let shipping = AIProduct.Shipping(length: length, weight: weight, width: width, height: height)

        return AIProduct(names: names,
                        descriptions: descriptions,
                        shortDescriptions: shortDescriptions,
                        virtual: virtual,
                        shipping: shipping,
                        tags: aiTags,
                        price: price,
                        categories: aiCategories)
    }
}

private enum MerchantGenerativeContentRemoteError: Error {
    case invalidResponse
}
