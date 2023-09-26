import Foundation

/// Used by backend to track AI-generation usage and measure costs
public enum GenerativeContentRemoteFeature: String {
    case productDescription = "woo_ios_product_description"
    case productSharing = "woo_ios_share_product"
    case productDetailsFromScannedTexts = "woo_ios_product_details_from_scanned_texts"
    case productName = "woo_ios_product_name"
    case productCreation = "woo_ios_product_creation"
}

/// Protocol for `GenerativeContentRemote` mainly used for mocking.
///
public protocol GenerativeContentRemoteProtocol {
    /// Generates text based on the given prompt using Jetpack AI. Currently, Jetpack AI is only supported for sites hosted on WPCOM.
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - base: Prompt for the AI-generated text.
    ///   - feature: Used by backend to track AI-generation usage and measure costs
    /// - Returns: AI-generated text based on the prompt if Jetpack AI is enabled.
    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature) async throws -> String

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
    ///   - productName: Product name to input to AI prompt
    ///   - keywords: Keywords describing the product to input for AI prompt
    ///   - language: Language to generate the product details
    ///   - tone: Tone of AI - Represented by `AIToneVoice`
    ///   - currencySymbol: Currency symbol to generate product price
    ///   - dimensionUnit: Weight unit to generate product dimensions
    ///   - weightUnit: Weight unit to generate product weight
    ///   - categories: Existing categories
    ///   - tags: Existing tags
    /// - Returns: Generated `Product`
    func generateProduct(siteID: Int64,
                         productName: String,
                         keywords: String,
                         language: String,
                         tone: String,
                         currencySymbol: String,
                         dimensionUnit: String?,
                         weightUnit: String?,
                         categories: [ProductCategory],
                         tags: [ProductTag]) async throws -> Product
}

/// Product: Remote Endpoints
///
public final class GenerativeContentRemote: Remote, GenerativeContentRemoteProtocol {
    private enum GenerativeContentRemoteError: Error {
        case tokenNotFound
    }

    private var token: String?

    public func generateText(siteID: Int64,
                             base: String,
                             feature: GenerativeContentRemoteFeature) async throws -> String {
        do {
            guard let token else {
                throw GenerativeContentRemoteError.tokenNotFound
            }
            return try await generateText(siteID: siteID, base: base, feature: feature, token: token)
        } catch GenerativeContentRemoteError.tokenNotFound,
                    WordPressApiError.unknown(code: TokenExpiredError.code, message: TokenExpiredError.message) {
            let token = try await fetchToken(siteID: siteID)
            self.token = token
            return try await generateText(siteID: siteID, base: base, feature: feature, token: token)
        }
    }

    public func identifyLanguage(siteID: Int64,
                                 string: String,
                                 feature: GenerativeContentRemoteFeature) async throws -> String {
        do {
            guard let token else {
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

    public func generateProduct(siteID: Int64,
                                productName: String,
                                keywords: String,
                                language: String,
                                tone: String,
                                currencySymbol: String,
                                dimensionUnit: String?,
                                weightUnit: String?,
                                categories: [ProductCategory],
                                tags: [ProductTag]) async throws -> Product {

        do {
            guard let token else {
                throw GenerativeContentRemoteError.tokenNotFound
            }
            return try await generateProduct(siteID: siteID,
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
            return try await generateProduct(siteID: siteID,
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
    func fetchToken(siteID: Int64) async throws -> String {
        let path = "sites/\(siteID)/\(Path.jwtToken)"
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path)
        let mapper = JWTTokenResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }

    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature,
                      token: String) async throws -> String {
        let parameters = [ParameterKey.token: token,
                          ParameterKey.prompt: base,
                          ParameterKey.feature: feature.rawValue,
                          ParameterKey.fields: ParameterValue.completion]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: Path.textCompletion,
                                    parameters: parameters)
        let mapper = TextCompletionResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }

    func identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature,
                          token: String) async throws -> String {
        let prompt = [
            "What is the ISO language code of the language used in the below text?" +
            "Do not include any explanations and only provide the ISO language code in your response.",
            "Text: ```\(string)```"
        ].joined(separator: "\n")
        let parameters = [ParameterKey.token: token,
                          ParameterKey.prompt: prompt,
                          ParameterKey.feature: feature.rawValue,
                          ParameterKey.fields: ParameterValue.completion]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: Path.textCompletion,
                                    parameters: parameters)
        let mapper = TextCompletionResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }


    func generateProduct(siteID: Int64,
                         productName: String,
                         keywords: String,
                         language: String,
                         tone: String,
                         currencySymbol: String,
                         dimensionUnit: String?,
                         weightUnit: String?,
                         categories: [ProductCategory],
                         tags: [ProductTag],
                         token: String) async throws -> Product {

        let tagsAsString = {
            guard !tags.isEmpty else {
                return ""
            }

            return
                ", tags: Given the list of available tags ```\(tags.map { $0.name }.joined(separator: ", "))```, " +
                "suggest an array of the best matching tags for this product, if no matches are found return an empty array, " +
                "don’t suggest any value other than the available ones."
        }()

        let categoriesAsString = {
            guard !categories.isEmpty else {
                return ""
            }

            return
                ", categories: Given the list of available categories ```\(categories.map { $0.name }.joined(separator: ", "))```, " +
                "suggest an array of the best matching categories for this product, if no matches are found return an empty array, " +
                "don’t suggest any value other than the available ones."
        }()

        let input = [
            "You are a WooCommerce SEO and marketing expert, perform in-depth research about the product " +
            "using the provided name, keywords and tone, and give your response in the below JSON format.",
            "name: ```\(productName)```",
            "keywords: ```\(keywords)```",
            "tone: ```\(tone)```",
        ].joined(separator: "\n")

        let expectedJsonFormat =
        "Expected json response format:" + "\n" +
        "{" +
            "name: The name of the product, in the ISO language code ```\(language)```, " +
            "description: Product description of around 100 words long in a ```\(tone)``` tone, in the ISO language code ```\(language)```, " +
            "short_description: Product's short description, in the ISO language code ```\(language)```, " +
            "virtual: A boolean value that shows whether the product is virtual or physical, " +
            "shipping: " +
                "{" +
                    "length: Guess and provide only the number in ```\(dimensionUnit)```, " +
                    "weight: Guess and provide only the number in ```\(weightUnit)```, " +
                    "width: Guess and provide only the number in ```\(dimensionUnit)```, " +
                    "height: Guess and provide only the number in ```\(dimensionUnit)```" +
                "}, " +
            "price: Guess the price in ```\(currencySymbol)```, return the price unformatted" +
            tagsAsString +
            categoriesAsString +
        "}"

        let prompt = input + "\n" + expectedJsonFormat

        let parameters = [ParameterKey.token: token,
                          ParameterKey.prompt: prompt,
                          ParameterKey.feature: GenerativeContentRemoteFeature.productCreation.rawValue,
                          ParameterKey.fields: ParameterValue.completion]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: Path.textCompletion,
                                    parameters: parameters)

        let mapper = AIProductMapper(siteID: siteID,
                                     existingCategories: categories,
                                     existingTags: tags)
        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - Constants
//
private extension GenerativeContentRemote {
    enum Path {
        static let textCompletion = "text-completion"
        static let jwtToken = "jetpack-openai-query/jwt"
    }

    enum ParameterKey {
        static let token = "token"
        static let prompt = "prompt"
        static let feature = "feature"
        static let fields = "_fields"
    }

    enum ParameterValue {
        static let completion = "completion"
    }

    enum TokenExpiredError {
        static let code = "rest_forbidden"
        static let message = "Sorry, you are not allowed to do that."
    }
}

// MARK: - Mapper to parse the JWT token
//
private struct JWTTokenResponseMapper: Mapper {
    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()
        return try decoder.decode(JWTTokenResponse.self, from: response).token
    }

    struct JWTTokenResponse: Decodable {
        let token: String
    }
}

// MARK: - Mapper to parse the `text-completion` endpoint response
//
private struct TextCompletionResponseMapper: Mapper {
    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()
        return try decoder.decode(TextCompletionResponse.self, from: response).completion
    }

    struct TextCompletionResponse: Decodable {
        let completion: String
    }
}
