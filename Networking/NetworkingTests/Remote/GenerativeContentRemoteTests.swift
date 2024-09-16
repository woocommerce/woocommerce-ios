import TestKit
import XCTest
import protocol Alamofire.URLRequestConvertible
@testable import Networking

final class GenerativeContentRemoteTests: XCTestCase {
    /// Mock Network Wrapper
    ///
    let network = MockNetwork()

    /// Sample Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - `generateText`

    func test_generateText_sends_correct_fields_value() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generative-text-success")

        // When
        _ = try await remote.generateText(siteID: sampleSiteID,
                                          base: "generate a product description for wapuu pencil",
                                          feature: .productDescription,
                                          responseFormat: .text)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let fieldsValue = try XCTUnwrap(request.parameters?["_fields"] as? String)
        XCTAssertEqual("choices", fieldsValue)
    }

    func test_generateText_sends_correct_response_format_value() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generative-text-success")

        // When
        _ = try await remote.generateText(siteID: sampleSiteID,
                                          base: "generate a product description for wapuu pencil",
                                          feature: .productDescription,
                                          responseFormat: .text)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let responseFormatValue = try XCTUnwrap(request.parameters?["response_format"] as? String)
        XCTAssertEqual("text", responseFormatValue)
    }

    func test_generateText_with_success_returns_generated_text() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generative-text-success")

        // When
        let generatedText = try await remote.generateText(siteID: sampleSiteID,
                                                          base: "generate a product description for wapuu pencil",
                                                          feature: .productDescription,
                                                          responseFormat: .text)

        // Then
        XCTAssertEqual(generatedText, "The Wapuu Pencil is a perfect writing tool for those who love cute things.")
    }

    func test_generateText_with_failure_returns_error() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generative-text-failure")

        // When
        await assertThrowsError {
            _ = try await remote.generateText(siteID: sampleSiteID,
                                              base: "generate a product description for wapuu pencil",
                                              feature: .productDescription,
                                              responseFormat: .text)
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "inactive", message: "OpenAI features have been disabled")
        }
    }

    func test_generateText_with_failure_returns_error_when_token_generation_fails() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-failure")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generative-text-failure")

        // When
        await assertThrowsError {
            _ = try await remote.generateText(siteID: sampleSiteID,
                                              base: "generate a product description for wapuu pencil",
                                              feature: .productDescription,
                                              responseFormat: .text)
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "oauth2_invalid_token", message: "The OAuth2 token is invalid.")
        }
    }

    func test_generateText_retries_after_regenarating_token_upon_receiving_403_error() async throws {
        // Given
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        let jetpackAIQueryPath = "jetpack-ai-query"
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: jwtRequestPath, filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "generative-text-success")

        // When
        _ = try await remote.generateText(siteID: sampleSiteID,
                                          base: "generate a product description for wapuu pencil",
                                          feature: .productDescription,
                                          responseFormat: .text)
        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)

        // When
        _ = try await remote.generateText(siteID: sampleSiteID,
                                          base: "generate a product description for wapuu pencil",
                                          feature: .productDescription,
                                          responseFormat: .text)

        // Then
        // Ensures that JWT is not requested again
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)


        // When
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "generative-text-invalid-token")
        _ = try? await remote.generateText(siteID: sampleSiteID,
                                           base: "generate a product description for wapuu pencil",
                                           feature: .productDescription,
                                           responseFormat: .text)

        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 2)
        XCTAssertEqual(numberOfJetpackAIQueryRequests(in: network.requestsForResponseData), 4)
    }

    func test_generateText_generates_token_if_token_expired() async throws {
        // Given
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        let jetpackAIQueryPath = "jetpack-ai-query"
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: jwtRequestPath, filename: "jwt-token-expired-token")
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "generative-text-success")

        // When
        _ = try await remote.generateText(siteID: sampleSiteID,
                                          base: "generate a product description for wapuu pencil",
                                          feature: .productDescription,
                                          responseFormat: .text)
        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)

        // When
        _ = try await remote.generateText(siteID: sampleSiteID,
                                          base: "generate a product description for wapuu pencil",
                                          feature: .productDescription,
                                          responseFormat: .text)

        // Then
        // Ensures that token is requested again
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 2)
    }

    // MARK: - `identifyLanguage`

    func test_identifyLanguage_sends_correct_fields_value() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "identify-language-success")

        // When
        _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                              string: "Woo is awesome.",
                                              feature: .productDescription)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let fieldsValue = try XCTUnwrap(request.parameters?["_fields"] as? String)
        XCTAssertEqual("choices", fieldsValue)
    }

    func test_identifyLanguage_with_success_returns_language_code() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "identify-language-success")

        // When
        let language = try await remote.identifyLanguage(siteID: sampleSiteID,
                                                         string: "Woo is awesome.",
                                                         feature: .productDescription)

        // Then
        XCTAssertEqual(language, "en")
    }

    func test_identifyLanguage_with_failure_returns_error() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "identify-language-failure")

        // When
        await assertThrowsError {
            _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                                  string: "Woo is awesome.",
                                                  feature: .productDescription)
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "inactive", message: "OpenAI features have been disabled")
        }
    }

    func test_identifyLanguage_with_failure_returns_error_when_token_generation_fails() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-failure")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "identify-language-failure")

        // When
        await assertThrowsError {
            _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                                  string: "Woo is awesome.",
                                                  feature: .productDescription)
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "oauth2_invalid_token", message: "The OAuth2 token is invalid.")
        }
    }

    func test_identifyLanguage_retries_after_regenarating_token_upon_receiving_403_error() async throws {
        // Given
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        let jetpackAIQueryPath = "jetpack-ai-query"
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: jwtRequestPath, filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "identify-language-success")

        // When
        _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                              string: "Woo is awesome.",
                                              feature: .productDescription)
        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)

        // When
        _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                              string: "Woo is awesome.",
                                              feature: .productDescription)

        // Then
        // Ensures that JWT is not requested again
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)


        // When
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "identify-language-invalid-token")
        _ = try? await remote.identifyLanguage(siteID: sampleSiteID,
                                               string: "Woo is awesome.",
                                               feature: .productDescription)

        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 2)
        XCTAssertEqual(numberOfJetpackAIQueryRequests(in: network.requestsForResponseData), 4)
    }

    func test_identifyLanguage_generates_token_if_token_expired() async throws {
        // Given
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        let jetpackAIQueryPath = "jetpack-ai-query"
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: jwtRequestPath, filename: "jwt-token-expired-token")
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "identify-language-success")

        // When
        _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                              string: "Woo is awesome.",
                                              feature: .productDescription)
        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)

        // When
        _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                              string: "Woo is awesome.",
                                              feature: .productDescription)

        // Then
        // Ensures that token is requested again
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 2)
    }

    // MARK: - `generateAIProduct`

    func test_generateAIProduct_sends_correct_fields_value() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [ProductCategory.fake(), ProductCategory.fake()],
                                               tags: [ProductTag.fake(), ProductTag.fake()])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let fieldsValue = try XCTUnwrap(request.parameters?["_fields"] as? String)
        XCTAssertEqual("choices", fieldsValue)
    }

    func test_generateAIProduct_sends_correct_feature_value() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [ProductCategory.fake(), ProductCategory.fake()],
                                               tags: [ProductTag.fake(), ProductTag.fake()])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let featureValue = try XCTUnwrap(request.parameters?["feature"] as? String)
        XCTAssertEqual("woo_ios_product_creation", featureValue)
    }

    func test_generateAIProduct_sends_correct_response_format_value() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [ProductCategory.fake(), ProductCategory.fake()],
                                               tags: [ProductTag.fake(), ProductTag.fake()])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let responseFormatValue = try XCTUnwrap(request.parameters?["response_format"] as? String)
        XCTAssertEqual("json_object", responseFormatValue)
    }

    func test_generateAIProduct_question_has_existing_categories() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [.init(categoryID: 1, siteID: sampleSiteID, parentID: 1, name: "Snacks", slug: ""),
                                                            .init(categoryID: 2, siteID: sampleSiteID, parentID: 1, name: "Makeup", slug: ""),
                                                            .init(categoryID: 3, siteID: sampleSiteID, parentID: 1, name: "Clothes", slug: "")],
                                               tags: [])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let question = try XCTUnwrap(request.parameters?["question"] as? String)
        XCTAssertTrue(question.contains("\"categories\":\"Given the list of available categories ```Snacks, Makeup, Clothes```, "
                                      + "suggest an array of the best matching categories for this product. You can suggest new categories as well.\""))
    }

    func test_generateAIProduct_question_asks_for_new_categories_if_no_categories_available() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [],
                                               tags: [.init(siteID: sampleSiteID, tagID: 1, name: "Food", slug: ""),
                                                      .init(siteID: sampleSiteID, tagID: 2, name: "Grocery", slug: "")])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let question = try XCTUnwrap(request.parameters?["question"] as? String)
        XCTAssertTrue(question.contains("\"categories\":\"Suggest an array of the best matching categories for this product.\""))
    }

    func test_generateAIProduct_question_has_existing_tags() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [],
                                               tags: [.init(siteID: sampleSiteID, tagID: 1, name: "Food", slug: ""),
                                                      .init(siteID: sampleSiteID, tagID: 2, name: "Grocery", slug: "")])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let question = try XCTUnwrap(request.parameters?["question"] as? String)
        XCTAssertTrue(question.contains("\"tags\":\"Given the list of available tags ```Food, Grocery```, "
                                      + "suggest an array of the best matching tags for this product. You can suggest new tags as well.\""))
    }

    func test_generateAIProduct_question_asks_for_new_tags_if_no_tags_available() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [],
                                               tags: [])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let question = try XCTUnwrap(request.parameters?["question"] as? String)
        XCTAssertTrue(question.contains("\"tags\":\"Suggest an array of the best matching tags for this product.\""))
    }

    func test_generateAIProduct_with_success_returns_AIProduct() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-success")

        // When
        let product = try await remote.generateAIProduct(siteID: sampleSiteID,
                                                         productName: "Cookie",
                                                         keywords: "Crunchy, Crispy",
                                                         language: "en",
                                                         tone: "Casual",
                                                         currencySymbol: "INR",
                                                         dimensionUnit: "cm",
                                                         weightUnit: "kg",
                                                         categories: [ProductCategory.fake(), ProductCategory.fake()],
                                                         tags: [ProductTag.fake(), ProductTag.fake()])

        // Then
        XCTAssertNotNil(product)
        XCTAssertEqual(product.names, ["Cookie", "Biscuits", "Crunchy Cookies Delight"])
        // swiftlint:disable line_length
        XCTAssertEqual(product.descriptions, ["Introducing Cookie, the ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Whether you're enjoying them with a cup of tea or sharing them with friends, Cookie is the go-to snack for any casual occasion. Indulge in the mouthwatering flavors and experience a taste sensation that will leave you wanting more. Get your hands on Cookie today and discover why it's the ultimate snack companion.", "Experience the ultimate crunchy delight with our premium crispy cookies. Perfectly baked to ensure every bite is packed with a satisfying crunch that will keep you coming back for more. These cookies are a great treat for any time of the day, whether you're enjoying them with a cup of coffee or as an after-meal dessert", "Our crispy cookies are crafted with the finest ingredients to deliver a superior crunch and taste. Each cookie is baked to a golden perfection, providing a uniquely satisfying munch that’s sure to please. A delicious snack that’s perfect for sharing and savoring every moment of crispy goodness."])
        XCTAssertEqual(product.shortDescriptions, ["The ultimate crunchy and crispy treat that will satisfy your snacking cravings", "Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite.", "Indulge in the mouthwatering flavors of Cookie today!"])
        // swiftlint:enable line_length
        XCTAssertFalse(product.virtual)
        XCTAssertEqual(product.shipping.weight, "0.2")
        XCTAssertEqual(product.shipping.length, "15")
        XCTAssertEqual(product.shipping.width, "10")
        XCTAssertEqual(product.shipping.height, "5")
        XCTAssertEqual(product.price, "250")
    }

    func test_generateAIProduct_with_failure_returns_error() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-failure")

        // When
        await assertThrowsError {
            _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                                   productName: "Cookie",
                                                   keywords: "Crunchy, Crispy",
                                                   language: "en",
                                                   tone: "Casual",
                                                   currencySymbol: "INR",
                                                   dimensionUnit: "cm",
                                                   weightUnit: "kg",
                                                   categories: [ProductCategory.fake(), ProductCategory.fake()],
                                                   tags: [ProductTag.fake(), ProductTag.fake()])
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "inactive", message: "OpenAI features have been disabled")
        }
    }

    func test_generateAIProduct_with_failure_returns_error_when_token_generation_fails() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-failure")
        network.simulateResponse(requestUrlSuffix: "jetpack-ai-query", filename: "generate-product-failure")

        // When
        await assertThrowsError {
            _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                                   productName: "Cookie",
                                                   keywords: "Crunchy, Crispy",
                                                   language: "en",
                                                   tone: "Casual",
                                                   currencySymbol: "INR",
                                                   dimensionUnit: "cm",
                                                   weightUnit: "kg",
                                                   categories: [ProductCategory.fake(), ProductCategory.fake()],
                                                   tags: [ProductTag.fake(), ProductTag.fake()])
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "oauth2_invalid_token", message: "The OAuth2 token is invalid.")
        }
    }

    func test_generateAIProduct_retries_after_regenarating_token_upon_receiving_403_error() async throws {
        // Given
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        let jetpackAIQueryPath = "jetpack-ai-query"
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: jwtRequestPath, filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [ProductCategory.fake(), ProductCategory.fake()],
                                               tags: [ProductTag.fake(), ProductTag.fake()])
        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [ProductCategory.fake(), ProductCategory.fake()],
                                               tags: [ProductTag.fake(), ProductTag.fake()])

        // Then
        // Ensures that JWT is not requested again
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)


        // When
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "generate-product-invalid-token")
        _ = try? await remote.generateAIProduct(siteID: sampleSiteID,
                                                productName: "Cookie",
                                                keywords: "Crunchy, Crispy",
                                                language: "en",
                                                tone: "Casual",
                                                currencySymbol: "INR",
                                                dimensionUnit: "cm",
                                                weightUnit: "kg",
                                                categories: [ProductCategory.fake(), ProductCategory.fake()],
                                                tags: [ProductTag.fake(), ProductTag.fake()])

        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 2)
        XCTAssertEqual(numberOfJetpackAIQueryRequests(in: network.requestsForResponseData), 4)
    }

    func test_generateAIProduct_generates_token_if_token_expired() async throws {
        // Given
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        let jetpackAIQueryPath = "jetpack-ai-query"
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: jwtRequestPath, filename: "jwt-token-expired-token")
        network.simulateResponse(requestUrlSuffix: jetpackAIQueryPath, filename: "generate-product-success")

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [ProductCategory.fake(), ProductCategory.fake()],
                                               tags: [ProductTag.fake(), ProductTag.fake()])
        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)

        // When
        _ = try await remote.generateAIProduct(siteID: sampleSiteID,
                                               productName: "Cookie",
                                               keywords: "Crunchy, Crispy",
                                               language: "en",
                                               tone: "Casual",
                                               currencySymbol: "INR",
                                               dimensionUnit: "cm",
                                               weightUnit: "kg",
                                               categories: [ProductCategory.fake(), ProductCategory.fake()],
                                               tags: [ProductTag.fake(), ProductTag.fake()])

        // Then
        // Ensures that token is requested again
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 2)
    }
}

// MARK: - Helpers
//
private extension GenerativeContentRemoteTests {
    func numberOfJwtRequests(in array: [URLRequestConvertible]) -> Int {
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        return array.filter({ request in
            guard let dotcomRequest = request as? DotcomRequest else {
                return false
            }
            return dotcomRequest.path == jwtRequestPath
        }).count
    }

    func numberOfJetpackAIQueryRequests(in array: [URLRequestConvertible]) -> Int {
        let jetpackAIQueryPath = "jetpack-ai-query"
        return array.filter({ request in
            guard let dotcomRequest = request as? DotcomRequest else {
                return false
            }
            return dotcomRequest.path == jetpackAIQueryPath
        }).count
    }
}
