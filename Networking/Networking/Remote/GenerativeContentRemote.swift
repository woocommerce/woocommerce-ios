import Foundation
import KeychainAccess

/// Used by backend to track AI-generation usage and measure costs
public enum GenerativeContentRemoteFeature: String {
    case productDescription = "woo_ios_product_description"
    case productSharing = "woo_ios_share_product"
    case productDetailsFromScannedTexts = "woo_ios_product_details_from_scanned_texts"
    case productName = "woo_ios_product_name"
    case productCreation = "woo_ios_product_creation"
}

public enum GenerativeContentRemoteResponseFormat: String {
    case json = "json_object"
    case text = "text"
}

public struct AIProviderKeyStorage {
    private let keychain: Keychain

    public init(keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) {
        self.keychain = keychain
    }
    
    // Returns the merchant AI API if available
    public var aiProviderAPIKey: String? {
        guard let key = keychain.aiProviderAPIKey else {
            return nil
        }
        return key
    }
}

private extension Keychain {
    private static let keychainAIProviderAPIKey = "aiProviderAPIKey"
    
    var aiProviderAPIKey: String? {
        get { self[Keychain.keychainAIProviderAPIKey] }
        set { self[Keychain.keychainAIProviderAPIKey] = newValue }
    }
}

/// Protocol for `GenerativeContentRemote` mainly used for mocking.
///
public protocol GenerativeContentRemoteProtocol {
    /// Generates text based on the given prompt using Jetpack AI. Currently, Jetpack AI is only supported for sites hosted on WPCOM.
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - base: Prompt for the AI-generated text.
    ///   - shouldUseMerchantAIKey: If should use the merchant's API key for AI functionalities
    ///   - feature: Used by backend to track AI-generation usage and measure costs
    ///   - responseFormat: enum parameter to specify response format.
    /// - Returns: AI-generated text based on the prompt if Jetpack AI is enabled.
    func generateText(siteID: Int64,
                      base: String,
                      shouldUseMerchantAIKey: Bool,
                      feature: GenerativeContentRemoteFeature,
                      responseFormat: GenerativeContentRemoteResponseFormat) async throws -> String

    /// Identifies the language from the given string
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - string: String from which we should identify the language
    ///   - shouldUseMerchantAIKey: If should use the merchant's API key for AI functionalities
    ///   - feature: Used by backend to track AI-generation usage and measure costs
    /// - Returns: ISO code of the language
    func identifyLanguage(siteID: Int64,
                          string: String,
                          shouldUseMerchantAIKey: Bool,
                          feature: GenerativeContentRemoteFeature) async throws -> String

    /// Generates a product using provided info
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - productName: Product name to input to AI prompt (optional)
    ///   - keywords: Keywords describing the product to input for AI prompt
    ///   - language: Language to generate the product details
    ///   - tone: Tone of AI - Represented by `AIToneVoice`
    ///   - shouldUseMerchantAIKey: If should use the merchant's API key for AI functionalities
    ///   - currencySymbol: Currency symbol to generate product price
    ///   - dimensionUnit: Weight unit to generate product dimensions
    ///   - weightUnit: Weight unit to generate product weight
    ///   - categories: Existing categories
    ///   - tags: Existing tags
    /// - Returns: Generated `AIProduct`
    func generateAIProduct(siteID: Int64,
                           productName: String?,
                           keywords: String,
                           language: String,
                           tone: String,
                           shouldUseMerchantAIKey: Bool,
                           currencySymbol: String,
                           dimensionUnit: String?,
                           weightUnit: String?,
                           categories: [ProductCategory],
                           tags: [ProductTag]) async throws -> AIProduct
}

/// Product: Remote Endpoints
///
public final class GenerativeContentRemote: Remote, GenerativeContentRemoteProtocol {
    private enum GenerativeContentRemoteError: Error {
        case tokenNotFound
    }

    private var token: JWToken?
    private var storage: AIProviderKeyStorage = AIProviderKeyStorage()

    public func generateText(siteID: Int64,
                             base: String,
                             shouldUseMerchantAIKey: Bool,
                             feature: GenerativeContentRemoteFeature,
                             responseFormat: GenerativeContentRemoteResponseFormat) async throws -> String {
        if shouldUseMerchantAIKey {
            return try await generateTextUsingMerchantAPIKey(base: base, responseFormat: responseFormat)
        } else {
            return try await generateTextUsingJetpack(siteID: siteID,
                                                      base: base,
                                                      feature: feature,
                                                      responseFormat: responseFormat)
        }
    }

    private func generateTextUsingJetpack(siteID: Int64,
                                          base: String,
                                          feature: GenerativeContentRemoteFeature,
                                          responseFormat: GenerativeContentRemoteResponseFormat) async throws -> String {
        do {
            guard let token, token.isTokenValid(for: siteID) else {
                throw GenerativeContentRemoteError.tokenNotFound
            }
            return try await generateText(siteID: siteID, base: base, feature: feature, responseFormat: responseFormat, token: token)
        } catch GenerativeContentRemoteError.tokenNotFound,
                WordPressApiError.unknown(code: TokenExpiredError.code, message: TokenExpiredError.message) {
            let token = try await fetchToken(siteID: siteID)
            self.token = token
            return try await generateText(siteID: siteID, base: base, feature: feature, responseFormat: responseFormat, token: token)
        }
    }

    private func generateTextUsingMerchantAPIKey(base: String,
                                                 responseFormat: GenerativeContentRemoteResponseFormat) async throws -> String {
        guard let key = storage.aiProviderAPIKey else {
            throw URLError(.unknown)
        }
        let selectedModel = UserDefaults.standard.string(forKey: "AIProviderModel") ?? ""
        let selectedProvider = AIProvider(rawValue: UserDefaults.standard.string(forKey: "AIProvider") ?? "OpenAI") ?? .openAI

        let request = try createAIRequest(
            provider: selectedProvider,
            apiKey: key,
            model: selectedModel,
            prompt: base
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw URLError(.cannotParseResponse)
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func identifyLanguage(siteID: Int64,
                                 string: String,
                                 shouldUseMerchantAIKey: Bool,
                                 feature: GenerativeContentRemoteFeature) async throws -> String {
        if shouldUseMerchantAIKey {
            return try await identifyLanguageUsingMerchantAPIKey(string: string)
        } else {
            return try await identifyLanguageUsingJetpack(siteID: siteID,
                                                          string: string,
                                                          feature: feature)
        }
    }

    private func identifyLanguageUsingJetpack(siteID: Int64,
                                              string: String,
                                              feature: GenerativeContentRemoteFeature) async throws -> String {
        do {
            guard let token, token.isTokenValid(for: siteID) else {
                throw GenerativeContentRemoteError.tokenNotFound
            }
            return try await identifyLanguage(siteID: siteID, string: string, feature: feature, token: token)
        } catch GenerativeContentRemoteError.tokenNotFound,
                WordPressApiError.unknown(code: TokenExpiredError.code, message: TokenExpiredError.message) {
            let token = try await fetchToken(siteID: siteID)
            self.token = token
            return try await identifyLanguage(siteID: siteID, string: string, feature: feature, token: token)
        }
    }

    private func identifyLanguageUsingMerchantAPIKey(string: String) async throws -> String {
        guard let key = storage.aiProviderAPIKey else {
            throw URLError(.unknown)
        }
        let selectedModel = UserDefaults.standard.string(forKey: "AIProviderModel") ?? ""
        let selectedProvider = AIProvider(rawValue: UserDefaults.standard.string(forKey: "AIProvider") ?? "OpenAI") ?? .openAI
        let prompt = String(format: AIRequestPrompts.identifyLanguage, string)

        let request = try createAIRequest(
                provider: selectedProvider,
                apiKey: key,
                model: selectedModel,
                prompt: prompt
            )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return try parseAIResponse(json: json, provider: selectedProvider)
    }

    public func generateAIProduct(siteID: Int64,
                                  productName: String?,
                                  keywords: String,
                                  language: String,
                                  tone: String,
                                  shouldUseMerchantAIKey: Bool,
                                  currencySymbol: String,
                                  dimensionUnit: String?,
                                  weightUnit: String?,
                                  categories: [ProductCategory],
                                  tags: [ProductTag]) async throws -> AIProduct {
        if shouldUseMerchantAIKey {
            return try await generateAIProductUsingMerchantAPIKey(productName: productName,
                                                                keywords: keywords,
                                                                language: language,
                                                                tone: tone,
                                                                currencySymbol: currencySymbol,
                                                                dimensionUnit: dimensionUnit,
                                                                weightUnit: weightUnit,
                                                                categories: categories,
                                                                tags: tags)
        } else {
            return try await generateAIProductUsingJetpack(siteID: siteID,
                                                        productName: productName,
                                                        keywords: keywords,
                                                        language: language,
                                                        tone: tone,
                                                        currencySymbol: currencySymbol,
                                                        dimensionUnit: dimensionUnit,
                                                        weightUnit: weightUnit,
                                                        categories: categories,
                                                        tags: tags)
        }
    }

    private func generateAIProductUsingJetpack(siteID: Int64,
                                            productName: String?,
                                            keywords: String,
                                            language: String,
                                            tone: String,
                                            currencySymbol: String,
                                            dimensionUnit: String?,
                                            weightUnit: String?,
                                            categories: [ProductCategory],
                                            tags: [ProductTag]) async throws -> AIProduct {
        do {
            guard let token, token.isTokenValid(for: siteID) else {
                throw GenerativeContentRemoteError.tokenNotFound
            }
            return try await generateAIProduct(siteID: siteID,
                                            productName: productName,
                                            keywords: keywords,
                                            language: language,
                                            tone: tone,
                                            currencySymbol: currencySymbol,
                                            dimensionUnit: dimensionUnit,
                                            weightUnit: weightUnit,
                                            categories: categories,
                                            tags: tags,
                                            token: token)
        } catch GenerativeContentRemoteError.tokenNotFound,
                WordPressApiError.unknown(code: TokenExpiredError.code, message: TokenExpiredError.message) {
            let token = try await fetchToken(siteID: siteID)
            self.token = token
            return try await generateAIProduct(siteID: siteID,
                                            productName: productName,
                                            keywords: keywords,
                                            language: language,
                                            tone: tone,
                                            currencySymbol: currencySymbol,
                                            dimensionUnit: dimensionUnit,
                                            weightUnit: weightUnit,
                                            categories: categories,
                                            tags: tags,
                                            token: token)
        }
    }

    private func generateAIProductUsingMerchantAPIKey(productName: String?,
                                                   keywords: String,
                                                   language: String,
                                                   tone: String,
                                                   currencySymbol: String,
                                                   dimensionUnit: String?,
                                                   weightUnit: String?,
                                                   categories: [ProductCategory],
                                                   tags: [ProductTag]) async throws -> AIProduct {
        let selectedProvider = AIProvider(rawValue: UserDefaults.standard.string(forKey: "AIProvider") ?? "OpenAI") ?? .openAI
        let selectedModel = UserDefaults.standard.string(forKey: "AIProviderModel") ?? ""

        var inputComponents = [String(format: AIRequestPrompts.inputComponents, keywords, tone)]

        if let productName = productName, !productName.isEmpty {
            inputComponents.insert("name: ```\(productName)```", at: 1)
        }

        let jsonResponseFormatDict = generateAIProductResponseFormat(
            tags: tags,
            categories: categories,
            language: language,
            tone: tone,
            currencySymbol: currencySymbol,
            dimensionUnit: dimensionUnit,
            weightUnit: weightUnit
        )

        let expectedJsonFormat = formatExpectedJsonResponse(jsonResponseFormatDict)

        let prompt = inputComponents.joined(separator: "\n") + "\n" + expectedJsonFormat

        guard let key = storage.aiProviderAPIKey else {
            throw URLError(.unknown)
        }
        
        let request = try createAIRequest(
                provider: selectedProvider,
                apiKey: key,
                model: selectedModel,
                prompt: prompt
            )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let contentString = try parseAIResponse(json: json, provider: selectedProvider)

        guard let data = contentString.data(using: .utf8),
              let productJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        // We don't need siteID for direct API calls, but need a new mapper
        let mapper = AIProductMapper(siteID: 0)
        return try mapper.map(dictionary: productJson)
    }
}

private extension GenerativeContentRemote {
    func fetchToken(siteID: Int64) async throws -> JWToken {
        let path = "sites/\(siteID)/\(Path.jwtToken)"
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path)
        let mapper = JWTokenMapper()
        return try await enqueue(request, mapper: mapper)
    }

    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature,
                      responseFormat: GenerativeContentRemoteResponseFormat?,
                      token: JWToken) async throws -> String {
        let parameters: [String: Any] = {
            var params = [String: Any]()
            params[ParameterKey.token] = token.token
            params[ParameterKey.question] = base
            params[ParameterKey.stream] = ParameterValue.stream
            params[ParameterKey.gptModel] = ParameterValue.gptModel
            params[ParameterKey.feature] = feature.rawValue
            params[ParameterKey.fields] = ParameterValue.choices
            if let responseFormat {
                params[ParameterKey.responseFormat] = responseFormat.rawValue
            }
            return params
        }()
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .get,
                                    path: Path.jetpackAIQuery,
                                    parameters: parameters)
        let mapper = JetpackAIQueryResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }

    func identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature,
                          token: JWToken) async throws -> String {
        let prompt = String(format: AIRequestPrompts.identifyLanguage, string)
        let parameters: [String: Any] = [ParameterKey.token: token.token,
                                         ParameterKey.question: prompt,
                                         ParameterKey.stream: ParameterValue.stream,
                                         ParameterKey.gptModel: ParameterValue.gptModel,
                                         ParameterKey.feature: feature.rawValue,
                                         ParameterKey.fields: ParameterValue.choices]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .get,
                                    path: Path.jetpackAIQuery,
                                    parameters: parameters)
        let mapper = JetpackAIQueryResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }

    func generateAIProduct(siteID: Int64,
                           productName: String?,
                           keywords: String,
                           language: String,
                           tone: String,
                           currencySymbol: String,
                           dimensionUnit: String?,
                           weightUnit: String?,
                           categories: [ProductCategory],
                           tags: [ProductTag],
                           token: JWToken) async throws -> AIProduct {
        var inputComponents = [String(format: AIRequestPrompts.inputComponents, keywords, tone)]

        // Name will be added only if `productName` is available.
        // TODO: this code related to `productName` can be removed after releasing the new product creation with AI flow. Github issue: 13108
        if let productName = productName, !productName.isEmpty {
            inputComponents.insert("name: ```\(productName)```", at: 1)
        }

        let input = inputComponents.joined(separator: "\n")

        let jsonResponseFormatDict = generateAIProductResponseFormat(
            tags: tags,
            categories: categories,
            language: language,
            tone: tone,
            currencySymbol: currencySymbol,
            dimensionUnit: dimensionUnit,
            weightUnit: weightUnit
        )

        let expectedJsonFormat = formatExpectedJsonResponse(jsonResponseFormatDict)

        let prompt = input + "\n" + expectedJsonFormat

        let parameters: [String: Any] = [ParameterKey.token: token.token,
                                         ParameterKey.question: prompt,
                                         ParameterKey.stream: ParameterValue.stream,
                                         ParameterKey.gptModel: ParameterValue.gptModel,
                                         ParameterKey.responseFormat: GenerativeContentRemoteResponseFormat.json.rawValue,
                                         ParameterKey.feature: GenerativeContentRemoteFeature.productCreation.rawValue,
                                         ParameterKey.fields: ParameterValue.choices,
                                         ParameterKey.maxTokens: ParameterValue.maxTokens]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .get,
                                    path: Path.jetpackAIQuery,
                                    parameters: parameters)

        let mapper = AIProductMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - Constants
//
private extension GenerativeContentRemote {
    enum Path {
        static let jetpackAIQuery = "jetpack-ai-query"
        static let jwtToken = "jetpack-openai-query/jwt"
    }

    enum ParameterKey {
        static let token = "token"
        static let question = "question"
        static let feature = "feature"
        static let fields = "_fields"
        static let stream = "stream"
        static let maxTokens = "max_tokens"
        static let responseFormat = "response_format"
        static let gptModel = "model"
    }

    enum ParameterValue {
        static let choices = "choices"
        static let stream = false
        static let gptModel = "gpt-4o"
        static let maxTokens = 4000
    }

    enum TokenExpiredError {
        static let code = "rest_forbidden"
        static let message = "Sorry, you are not allowed to do that."
    }
}

// MARK: - Helper to check token validity
//
private extension JWToken {
    func isTokenValid(for currentSelectedSiteID: Int64) -> Bool {
        expiryDate > Date() && siteID == currentSelectedSiteID
    }
}

private struct AIRequestPrompts {
    static let identifyLanguage = [
        "What is the ISO language code of the language used in the below text?",
        "Do not include any explanations and only provide the ISO language code in your response.",
        "Text: ```%@"
    ].joined(separator: "\n")

    static let inputComponents = [
        "You are a WooCommerce SEO and marketing expert, perform in-depth research about the product " +
        "using the provided name, keywords, and tone, and give your response in the below JSON format.",
        "keywords: ```%@```",
        "tone: ```%@```"
    ].joined(separator: "\n")
}

private extension GenerativeContentRemote {
    private enum AIProvider: String {
        case openAI = "OpenAI"
        case anthropic = "Anthropic"

        var requestURL: String {
            switch self {
            case .openAI:
                return "https://api.openai.com/v1/chat/completions"
            case .anthropic:
                return "https://api.anthropic.com/v1/messages"
            }
        }
    }

    private func createAIRequest(provider: AIProvider, apiKey: String, model: String, prompt: String) throws -> URLRequest {
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": ParameterValue.maxTokens
        ]

        let requestData = try JSONSerialization.data(withJSONObject: requestBody)
        var request = URLRequest(url: URL(string: provider.requestURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        switch provider {
        case .openAI:
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        case .anthropic:
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        }

        return request
    }

    private func parseAIResponse(json: [String: Any]?, provider: AIProvider) throws -> String {
        if provider == .openAI {
            // openAI
            guard let choices = json?["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw URLError(.cannotParseResponse)
            }
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // Anthropic // TODO: Switch to be explicit
            guard let content = json?["content"] as? [[String: Any]],
                  let text = content.first?["text"] as? String else {
                throw URLError(.cannotParseResponse)
            }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func formatExpectedJsonResponse(_ jsonResponseFormat: [String: Any]) -> String {
        return "Your response should be in JSON format and don't send anything extra. " +
               "Don't include the word JSON in your response:\n" +
               (jsonResponseFormat.toJSONEncoded() ?? "")
    }

    private func generateAIProductResponseFormat(tags: [ProductTag],
                                                 categories: [ProductCategory],
                                                 language: String,
                                                 tone: String,
                                                 currencySymbol: String,
                                                 dimensionUnit: String?,
                                                 weightUnit: String?) -> [String: Any] {
        let tagsPrompt: String = {
            guard !tags.isEmpty else {
                return "Suggest an array of the best matching tags for this product."
            }
            return "Given the list of available tags ```\(tags.map { $0.name }.joined(separator: ", "))```, " +
                   "suggest an array of the best matching tags for this product. You can suggest new tags as well."
        }()

        let categoriesPrompt: String = {
            guard !categories.isEmpty else {
                return "Suggest an array of the best matching categories for this product."
            }
            return "Given the list of available categories ```\(categories.map { $0.name }.joined(separator: ", "))```, " +
                   "suggest an array of the best matching categories for this product. You can suggest new categories as well."
        }()

        let shippingPrompt = {
            var dict = [String: String]()
            if let weightUnit {
                dict["weight"] = "Guess and provide only the number in \(weightUnit)"
            }
            if let dimensionUnit {
                dict["length"] = "Guess and provide only the number in \(dimensionUnit)"
                dict["width"] = "Guess and provide only the number in \(dimensionUnit)"
                dict["height"] = "Guess and provide only the number in \(dimensionUnit)"
            }
            return dict
        }()

        // swiftlint:disable line_length
        return [
            "names": "An array of strings, containing three different names of the product, written in the language with ISO code ```\(language)```",
            "descriptions": "An array of strings, each containing three different product descriptions of around 100 words long each in a ```\(tone)``` tone, " +
                            "written in the language with ISO code ```\(language)```",
            "short_descriptions": "An array of strings, each containing three different short descriptions of the product in a ```\(tone)``` tone, " +
                                  "written in the language with ISO code ```\(language)```",
            "virtual": "A boolean value that shows whether the product is virtual or physical",
            "shipping": shippingPrompt,
            "price": "Guess the price in \(currencySymbol), do not include the currency symbol, only provide the price as a number",
            "tags": tagsPrompt,
            "categories": categoriesPrompt
        ]
    }
}
