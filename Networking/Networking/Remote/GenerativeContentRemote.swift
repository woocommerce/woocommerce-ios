import Foundation

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

/// Protocol for `GenerativeContentRemote` mainly used for mocking.
///
public protocol GenerativeContentRemoteProtocol {
    /// Generates text based on the given prompt using Jetpack AI. Currently, Jetpack AI is only supported for sites hosted on WPCOM.
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - base: Prompt for the AI-generated text.
    ///   - feature: Used by backend to track AI-generation usage and measure costs
    ///   - responseFormat: enum parameter to specify response format.
    /// - Returns: AI-generated text based on the prompt if Jetpack AI is enabled.
    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature,
                      responseFormat: GenerativeContentRemoteResponseFormat) async throws -> String

    /// Identifies the language from the given string
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - string: String from which we should identify the language
    ///   - feature: Used by backend to track AI-generation usage and measure costs
    /// - Returns: ISO code of the language
    func identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature) async throws -> String

    /// Generates a product using provided info
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - productName: Product name to input to AI prompt (optional)
    ///   - keywords: Keywords describing the product to input for AI prompt
    ///   - language: Language to generate the product details
    ///   - tone: Tone of AI - Represented by `AIToneVoice`
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

    public func generateText(siteID: Int64,
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

    public func identifyLanguage(siteID: Int64,
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
        let prompt = [
            "What is the ISO language code of the language used in the below text?" +
            "Do not include any explanations and only provide the ISO language code in your response.",
            "Text: ```\(string)```"
        ].joined(separator: "\n")
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
        var inputComponents = [
            "You are a WooCommerce SEO and marketing expert, perform in-depth research about the product " +
            "using the provided name, keywords and tone, and give your response in the below JSON format.",
            "keywords: ```\(keywords)```",
            "tone: ```\(tone)```",
        ]

        // Name will be added only if `productName` is available.
        // TODO: this code related to `productName` can be removed after releasing the new product creation with AI flow. Github issue: 13108
        if let productName = productName, !productName.isEmpty {
            inputComponents.insert("name: ```\(productName)```", at: 1)
        }

        let input = inputComponents.joined(separator: "\n")

        let jsonResponseFormatDict: [String: Any] = {
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
            return ["names": "An array of strings, containing three different names of the product, written in the language with ISO code ```\(language)```",
                    "descriptions": "An array of strings, each containing three different product descriptions of around 100 words long each in a ```\(tone)``` tone, "
                    + "written in the language with ISO code ```\(language)```",
                    "short_descriptions": "An array of strings, each containing three different short descriptions of the product in a ```\(tone)``` tone, "
                    + "written in the language with ISO code ```\(language)```",
                    "virtual": "A boolean value that shows whether the product is virtual or physical",
                    "shipping": shippingPrompt,
                    "price": "Guess the price in \(currencySymbol), do not include the currency symbol, "
                    + "only provide the price as a number",
                    "tags": tagsPrompt,
                    "categories": categoriesPrompt]
        }()

        let expectedJsonFormat =
        "Your response should be in JSON format and don't send anything extra. " +
        "Don't include the word JSON in your response:" +
        "\n" +
        (jsonResponseFormatDict.toJSONEncoded() ?? "")

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
