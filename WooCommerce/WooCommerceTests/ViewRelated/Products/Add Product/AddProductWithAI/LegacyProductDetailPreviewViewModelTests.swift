import XCTest
@testable import Yosemite
@testable import WooCommerce

@MainActor
final class LegacyProductDetailPreviewViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 123
    private var stores: MockStoresManager!
    private var storage: MockStorageManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        stores = MockStoresManager(sessionManager: .makeForTesting())
        storage = MockStorageManager()
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        stores = nil
        storage = nil
        super.tearDown()
    }

    // MARK: `generateProductDetails`

    func test_generateProductDetails_fetches_site_settings_if_weight_unit_is_nil() async {
        // Given
        let productName = "Pen"
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: productName,
                                                            productDescription: nil,
                                                            productFeatures: productFeatures,
                                                            weightUnit: nil,
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .synchronizeGeneralSiteSettings(siteID, completion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                completion(nil)
            case let .synchronizeProductSiteSettings(siteID, completion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                completion(nil)
            default:
                break
            }
        }

        mockProductActions()
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
    }

    func test_generateProductDetails_fetches_site_settings_if_dimension_unit_is_nil() async {
        // Given
        let productName = "Pen"
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: productName,
                                                            productDescription: nil,
                                                            productFeatures: productFeatures,
                                                            dimensionUnit: nil,
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .synchronizeGeneralSiteSettings(siteID, completion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                completion(nil)
            case let .synchronizeProductSiteSettings(siteID, completion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                completion(nil)
            default:
                break
            }
        }

        mockProductActions()
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
    }

    func test_generateProductDetails_synchronizes_categories() async {
        // Given
        let productName = "Pen"
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: productName,
                                                            productDescription: nil,
                                                            productFeatures: productFeatures,
                                                            weightUnit: nil,
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockSettingActions()
        mockProductActions()
        mockProductTagActions()

        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .synchronizeProductCategories(siteID, _, completion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                completion(nil)
            default:
                break
            }
        }

        // When
        await viewModel.generateProductDetails()
    }

    func test_generateProductDetails_synchronizes_tags() async {
        // Given
        let productName = "Pen"
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: productName,
                                                            productDescription: nil,
                                                            productFeatures: productFeatures,
                                                            weightUnit: nil,
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockSettingActions()
        mockProductActions()
        mockProductCategoryActions()

        stores.whenReceivingAction(ofType: ProductTagAction.self) { action in
            switch action {
            case let .synchronizeAllProductTags(siteID, completion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                completion(nil)
            default:
                break
            }
        }

        // When
        await viewModel.generateProductDetails()
    }

    func test_generateProductDetails_sends_name_and_features_to_identify_language() async throws {
        // Given
        let productName = "Pen"
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: productName,
                                                            productDescription: nil,
                                                            productFeatures: productFeatures,
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })
        XCTAssertFalse(viewModel.isGeneratingDetails)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateAIProduct(_, _, _, _, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .identifyLanguage(_, string, _, completion):
                // Then
                XCTAssertEqual(string, productName + " " + productFeatures)
                completion(.success("en"))
            default:
                break
            }
        }

        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
    }

    func test_identified_language_is_reused_when_generating_product_details_again() async {
        // Given
        let productName = "Pen"
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"
        let expectedLanguage = "en"
        var identifyingLanguageRequestCount = 0

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: 123,
                                                            productName: productName,
                                                            productDescription: nil,
                                                            productFeatures: productFeatures,
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateAIProduct(_, _, _, language, _, _, _, _, _, _, completion):
                XCTAssertEqual(language, expectedLanguage)
                completion(.success(.fake()))
            case let .identifyLanguage(_, _, _, completion):
                identifyingLanguageRequestCount += 1
                completion(.success(expectedLanguage))
            default:
                break
            }
        }

        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
        // Retry once
        await viewModel.generateProductDetails()

        // Then
        XCTAssertEqual(identifyingLanguageRequestCount, 1)
    }

    func test_generateProductDetails_sends_correct_values_to_generate_product_details() async throws {
        // Given
        let sampleSiteID: Int64 = 123
        let sampleProductName = "Pen"
        let sampleProductFeatures = "Ballpoint, Blue ink, ABS plastic"
        let sampleLanguage = "en"
        let sampleTone = AIToneVoice.convincing
        let sampleCurrency = "₹"
        let sampleWeightUnit = "kg"
        let sampleDimensionUnit = "cm"

        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.aiPromptTone] = ["\(sampleSiteID)": sampleTone.rawValue]

        let sampleCategories = [ProductCategory.fake().copy(siteID: sampleSiteID), ProductCategory.fake().copy(siteID: sampleSiteID)]
        sampleCategories.forEach { storage.insertSampleProductCategory(readOnlyProductCategory: $0) }

        let sampleTags = [ProductTag.fake().copy(siteID: sampleSiteID), ProductTag.fake().copy(siteID: sampleSiteID)]
        sampleTags.forEach { storage.insertSampleProductTag(readOnlyProductTag: $0) }

        // Insert categories and tags for other site to test correct items that belong to current site are sent
        storage.insertSampleProductCategory(readOnlyProductCategory: .fake().copy(siteID: 321))
        storage.insertSampleProductTag(readOnlyProductTag: .fake().copy(siteID: 321))

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: sampleProductName,
                                                            productDescription: nil,
                                                            productFeatures: sampleProductFeatures,
                                                            currency: sampleCurrency,
                                                            weightUnit: sampleWeightUnit,
                                                            dimensionUnit: sampleDimensionUnit,
                                                            stores: stores,
                                                            storageManager: storage,
                                                            userDefaults: userDefaults,
                                                            onProductCreated: { _ in })
        XCTAssertFalse(viewModel.isGeneratingDetails)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let  .generateAIProduct(siteID,
                                         productName,
                                         keywords,
                                         language,
                                         tone,
                                         currencySymbol,
                                         dimensionUnit,
                                         weightUnit,
                                         categories,
                                         tags,
                                         completion):
                // Then
                XCTAssertEqual(siteID, sampleSiteID)
                XCTAssertEqual(productName, sampleProductName)
                XCTAssertEqual(keywords, sampleProductFeatures)
                XCTAssertEqual(language, sampleLanguage)
                XCTAssertEqual(tone, sampleTone.rawValue)
                XCTAssertEqual(currencySymbol, sampleCurrency)
                XCTAssertEqual(dimensionUnit, sampleDimensionUnit)
                XCTAssertEqual(weightUnit, sampleWeightUnit)
                XCTAssertEqual(categories, sampleCategories)
                XCTAssertEqual(tags, sampleTags)
                completion(.success(.fake()))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success(sampleLanguage))
            default:
                break
            }
        }

        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
    }

    func test_generateProductDetails_sends_productDescription_if_available_to_generate_product_details() async {
        // Given
        let sampleProductName = "Pen"
        let sampleProductDescription = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: sampleProductName,
                                                            productDescription: sampleProductDescription,
                                                            productFeatures: nil,
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })
        XCTAssertFalse(viewModel.isGeneratingDetails)

        mockProductActions()
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
    }

    func test_generateProductDetails_updates_generationInProgress_correctly() async throws {
        // Given
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: 123,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })
        XCTAssertFalse(viewModel.isGeneratingDetails)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateAIProduct(_, _, _, _, _, _, _, _, _, _, completion):
                XCTAssertTrue(viewModel.isGeneratingDetails)
                completion(.success(.fake()))
            case let .identifyLanguage(_, _, _, completion):
                XCTAssertTrue(viewModel.isGeneratingDetails)
                completion(.success("en"))
            default:
                break
            }
        }

        mockProductTagActions()
        mockProductCategoryActions()

        await viewModel.generateProductDetails()

        // Then
        XCTAssertFalse(viewModel.isGeneratingDetails)
    }

    func test_errorState_is_updated_when_generateProductDetails_fails() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 503)
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: 123,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })
        XCTAssertEqual(viewModel.errorState, .none)

        mockProductTagActions()
        mockProductCategoryActions()

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateAIProduct(_, _, _, _, _, _, _, _, _, _, completion):
                XCTAssertEqual(viewModel.errorState, .none)
                completion(.failure(expectedError))
            case let .identifyLanguage(_, _, _, completion):
                XCTAssertEqual(viewModel.errorState, .none)
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()

        // Then
        XCTAssertEqual(viewModel.errorState, .generatingProduct)
    }

    func test_generateProductDetails_updates_generatedProduct_correctly() async throws {
        // Given
        let siteID: Int64 = 123
        let name = "Pen"
        let description = "Sample description"
        let shortDescription = "Sample short description"
        let virtual = true
        let weight = "0.2"
        let length = "0.2"
        let width = "0.2"
        let height = "0.2"
        let price = "0.2"

        let aiProduct = AIProduct(names: [name],
                                  descriptions: [description],
                                  shortDescriptions: [shortDescription],
                                  virtual: virtual,
                                  shipping: .init(length: length, weight: weight, width: width, height: height),
                                  tags: [],
                                  price: price,
                                  categories: [])

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: siteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        let generatedProduct = try XCTUnwrap(viewModel.generatedProduct)
        XCTAssertEqual(generatedProduct.siteID, siteID)
        XCTAssertEqual(generatedProduct.name, name)
        XCTAssertEqual(generatedProduct.fullDescription, description)
        XCTAssertEqual(generatedProduct.shortDescription, shortDescription)
        XCTAssertTrue(generatedProduct.virtual)
        XCTAssertEqual(generatedProduct.dimensions.width, width)
        XCTAssertEqual(generatedProduct.dimensions.height, height)
        XCTAssertEqual(generatedProduct.dimensions.length, length)
        XCTAssertEqual(generatedProduct.weight, weight)
        XCTAssertEqual(generatedProduct.regularPrice, price)
    }

    func test_generateProductDetails_generates_product_with_matching_existing_categories() async throws {
        // Given
        let sampleSiteID: Int64 = 123
        let biscuit = ProductCategory.fake().copy(siteID: sampleSiteID, name: "Biscuits")
        let product = AIProduct.fake().copy(categories: [biscuit.name])

        let sampleCategories = [biscuit, ProductCategory.fake().copy(siteID: sampleSiteID)]
        sampleCategories.forEach { storage.insertSampleProductCategory(readOnlyProductCategory: $0) }

        let sampleTags = [ProductTag.fake().copy(siteID: sampleSiteID), ProductTag.fake().copy(siteID: sampleSiteID)]
        sampleTags.forEach { storage.insertSampleProductTag(readOnlyProductTag: $0) }

        // Insert categories and tags for other site to test correct items that belong to current site are sent
        storage.insertSampleProductCategory(readOnlyProductCategory: .fake().copy(siteID: 321))
        storage.insertSampleProductTag(readOnlyProductTag: .fake().copy(siteID: 321))

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        let generatedProduct = try XCTUnwrap(viewModel.generatedProduct)
        XCTAssertEqual(generatedProduct.categories, [biscuit])
    }

    func test_generateProductDetails_generates_product_with_new_categories_suggested_by_AI() async throws {
        // Given
        let product = AIProduct.fake().copy(categories: ["Biscuits", "Cookies"])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        let generatedProduct = try XCTUnwrap(viewModel.generatedProduct)
        XCTAssertEqual(generatedProduct.categories.map { $0.name }, ["Biscuits", "Cookies"])
        XCTAssertEqual(generatedProduct.categories.map { $0.categoryID }, [0, 0])
    }

    func test_generateProductDetails_generates_product_with_matching_existing_tags() async throws {
        // Given
        let food: ProductTag = .fake().copy(siteID: sampleSiteID, name: "Food")
        let product = AIProduct.fake().copy(tags: [food.name])

        let sampleCategories = [ProductCategory.fake().copy(siteID: sampleSiteID), ProductCategory.fake().copy(siteID: sampleSiteID)]
        sampleCategories.forEach { storage.insertSampleProductCategory(readOnlyProductCategory: $0) }

        let sampleTags = [food, ProductTag.fake().copy(siteID: sampleSiteID)]
        sampleTags.forEach { storage.insertSampleProductTag(readOnlyProductTag: $0) }

        // Insert categories and tags for other site to test correct items that belong to current site are sent
        storage.insertSampleProductCategory(readOnlyProductCategory: .fake().copy(siteID: 321))
        storage.insertSampleProductTag(readOnlyProductTag: .fake().copy(siteID: 321))

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        let generatedProduct = try XCTUnwrap(viewModel.generatedProduct)
        XCTAssertEqual(generatedProduct.tags, [food])
    }

    func test_generateProductDetails_generates_product_with_new_tags_suggested_by_AI() async throws {
        // Given
        let product = AIProduct.fake().copy(tags: ["Food", "Grocery"])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        let generatedProduct = try XCTUnwrap(viewModel.generatedProduct)
        XCTAssertEqual(generatedProduct.tags.map { $0.name }, ["Food", "Grocery"])
        XCTAssertEqual(generatedProduct.tags.map { $0.tagID }, [0, 0])
    }

    func test_generateProductDetails_switches_to_given_productName_if_AIProduct_has_empty_name() async throws {
        // Given
        let product = AIProduct.fake().copy(names: [""], descriptions: ["Test description"])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        let generatedProduct = try XCTUnwrap(viewModel.generatedProduct)
        XCTAssertEqual(generatedProduct.name, "Pen")
    }

    // MARK: Short description view

    func test_short_description_view_is_shown_if_shortDescription_is_not_empty() async {
        // Given
        let product = AIProduct.fake().copy(shortDescriptions: ["A short description"])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: "Blue plastic ballpoint pen",
                                                            productFeatures: nil,
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        XCTAssertTrue(viewModel.shouldShowShortDescriptionView)
    }

    func test_short_description_view_is_hidden_if_shortDescription_empty() async {
        // Given
        let product = AIProduct.fake().copy(shortDescriptions: [""])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: "Blue plastic ballpoint pen",
                                                            productFeatures: nil,
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        XCTAssertFalse(viewModel.shouldShowShortDescriptionView)
    }

    func test_short_description_view_is_hidden_if_shortDescription_nil() async {
        // Given
        let product = AIProduct.fake().copy(shortDescriptions: nil)
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: "Blue plastic ballpoint pen",
                                                            productFeatures: nil,
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        XCTAssertFalse(viewModel.shouldShowShortDescriptionView)
    }

    func test_short_description_view_is_shown_while_generating_AI_details() async {
        // Given
        let product = AIProduct.fake().copy(names: ["Test name"], descriptions: [""], shortDescriptions: [""])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: "Blue plastic ballpoint pen",
                                                            productFeatures: nil,
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateAIProduct(_, _, _, _, _, _, _, _, _, _, completion):
                // Then
                XCTAssertTrue(viewModel.shouldShowShortDescriptionView)
                completion(.success(product))
            case let .identifyLanguage(_, _, _, completion):
                // Then
                XCTAssertTrue(viewModel.shouldShowShortDescriptionView)
                completion(.success("en"))
            default:
                break
            }
        }

        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        XCTAssertFalse(viewModel.shouldShowShortDescriptionView)
    }

    // MARK: - Save product

    func test_saveProductAsDraft_updates_isSavingProduct_properly() async {
        // Given
        let aiProduct = AIProduct.fake().copy(names: ["iPhone 15"])
        let expectedProduct = Product(siteID: 123,
                                      name: "iPhone 15",
                                      fullDescription: "Description",
                                      shortDescription: "Short description",
                                      aiProduct: aiProduct,
                                      categories: [],
                                      tags: [])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: 123,
                                                            productName: "iPhone 15",
                                                            productDescription: nil,
                                                            productFeatures: "",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            onProductCreated: { _ in })

        mockProductTagActions()
        mockProductCategoryActions()

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateAIProduct(_, _, _, _, _, _, _, _, _, _, completion):
                XCTAssertFalse(viewModel.isSavingProduct)
                completion(.success(aiProduct))
            case let .identifyLanguage(_, _, _, completion):
                XCTAssertFalse(viewModel.isSavingProduct)
                completion(.success("en"))
            case let .addProduct(_, onCompletion):
                XCTAssertTrue(viewModel.isSavingProduct)
                onCompletion(.success(expectedProduct))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertFalse(viewModel.isSavingProduct)
    }

    func test_saveProductAsDraft_success_triggers_onProductCreated() async {
        // Given
        var createdProduct: Product?
        let aiProduct = AIProduct.fake().copy(names: ["iPhone 15"])
        let expectedProduct = Product(siteID: 123,
                                      name: "iPhone 15",
                                      fullDescription: "Description",
                                      shortDescription: "Short description",
                                      aiProduct: aiProduct,
                                      categories: [],
                                      tags: [])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: 123,
                                                            productName: "iPhone 15",
                                                            productDescription: nil,
                                                            productFeatures: "",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            onProductCreated: { createdProduct = $0 })

        mockProductTagActions()
        mockProductCategoryActions()
        mockProductActions(aiGeneratedProductResult: .success(aiProduct),
                           addedProductResult: .success(expectedProduct))

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertEqual(createdProduct, expectedProduct)
    }

    func test_saveProductAsDraft_updates_errorState_upon_failure() async {
        // Given
        let aiProduct = AIProduct.fake().copy(names: ["iPhone 15"])
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: 123,
                                                            productName: "iPhone 15",
                                                            productDescription: nil,
                                                            productFeatures: "",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            onProductCreated: { _ in })
        XCTAssertEqual(viewModel.errorState, .none)

        mockProductTagActions()
        mockProductCategoryActions()
        mockProductActions(aiGeneratedProductResult: .success(aiProduct),
                           addedProductResult: .failure(.unexpected))

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertEqual(viewModel.errorState, .savingProduct)
    }

    func test_saveProductAsDraft_saves_local_categories() async {
        // Given
        let grocery = ProductCategory.fake().copy(siteID: sampleSiteID, name: "Groceries")
        let aiProduct = AIProduct.fake().copy(names: ["iPhone 15"],
                                              categories: ["Biscuits", "Cookies"])

        let sampleCategories = [grocery]
        sampleCategories.forEach { storage.insertSampleProductCategory(readOnlyProductCategory: $0) }

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "iPhone 15",
                                                            productDescription: nil,
                                                            productFeatures: "",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .synchronizeProductCategories(_, _, completion):
                completion(nil)
            case let .addProductCategories(siteID, names, _, completion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                XCTAssertEqual(names, ["Biscuits", "Cookies"])
                completion(.success([]))
            default:
                break
            }
        }

        mockProductTagActions()
        mockProductActions(aiGeneratedProductResult: .success(aiProduct))

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()
    }

    func test_saveProductAsDraft_saves_local_tags() async {
        // Given
        let existingTag = ProductTag.fake().copy(siteID: sampleSiteID, name: "Existing tag")
        let aiProduct = AIProduct.fake().copy(names: ["iPhone 15"],
                                              tags: ["Tag 1", "Tag 2"])

        let sampleTags = [existingTag, ProductTag.fake().copy(siteID: sampleSiteID)]
        sampleTags.forEach { storage.insertSampleProductTag(readOnlyProductTag: $0) }

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "iPhone 15",
                                                            productDescription: nil,
                                                            productFeatures: "",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            onProductCreated: { _ in })

        mockProductCategoryActions()
        mockProductActions(aiGeneratedProductResult: .success(aiProduct))

        stores.whenReceivingAction(ofType: ProductTagAction.self) { action in
            switch action {
            case let .synchronizeAllProductTags(_, completion):
                completion(nil)
            case let .addProductTags(siteID, tags, completion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                XCTAssertEqual(tags, ["Tag 1", "Tag 2"])
                completion(.success([]))
            default:
                break
            }
        }

        await viewModel.generateProductDetails()

        // When
        await viewModel.saveProductAsDraft()
    }

    // MARK: - Handle feedback

    func test_handleFeedback_sets_shouldShowFeedbackView_to_false() {
        // Given
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            analytics: analytics,
                                                            onProductCreated: { _ in })

        // When
        viewModel.handleFeedback(.up)

        // Then
        XCTAssertFalse(viewModel.shouldShowFeedbackView)
    }

    // MARK: Analytics

    func test_generateProductDetails_tracks_event_on_success() async throws {
        // Given
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            analytics: analytics,
                                                            onProductCreated: { _ in })

        mockProductTagActions()
        mockProductCategoryActions()
        mockProductActions()

        // When
        await viewModel.generateProductDetails()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_generate_product_details_success"))
    }

    func test_generateProductDetails_tracks_event_on_failure() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 503)

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            analytics: analytics,
                                                            onProductCreated: { _ in })

        mockProductTagActions()
        mockProductCategoryActions()
        mockProductActions(aiGeneratedProductResult: .failure(expectedError))

        // When
        await viewModel.generateProductDetails()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_generate_product_details_failed"))

        let errorEventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_creation_ai_generate_product_details_failed"}))
        let errorEventProperties = analyticsProvider.receivedProperties[errorEventIndex]
        XCTAssertEqual(errorEventProperties["error_code"] as? String, "503")
        XCTAssertEqual(errorEventProperties["error_domain"] as? String, "test")
    }

    func test_saveProductAsDraft_tracks_tapped_event() async {
        // Given
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            analytics: analytics,
                                                            onProductCreated: { _ in })

        mockProductActions()

        // When
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_save_as_draft_button_tapped"))
    }

    func test_saveProductAsDraft_tracks_event_on_success() async throws {
        // Given
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            analytics: analytics,
                                                            onProductCreated: { _ in })
        mockProductTagActions()
        mockProductCategoryActions()
        mockProductActions()

        await viewModel.generateProductDetails()

        // When
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_save_as_draft_success"))
    }

    func test_saveProductAsDraft_tracks_event_on_failure() async throws {
        // Given
        let expectedError = ProductUpdateError(error: NSError(domain: "test", code: 503))

        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            analytics: analytics,
                                                            onProductCreated: { _ in })

        mockProductTagActions()
        mockProductCategoryActions()
        mockProductActions(addedProductResult: .failure(expectedError))

        await viewModel.generateProductDetails()

        // When
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_save_as_draft_failed"))

        let errorEventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_creation_ai_save_as_draft_failed"}))
        let errorEventProperties = analyticsProvider.receivedProperties[errorEventIndex]
        XCTAssertEqual(errorEventProperties["error_code"] as? String, "0")
        XCTAssertEqual(errorEventProperties["error_domain"] as? String, "Yosemite.ProductUpdateError")
    }

    func test_handleFeedback_tracks_feedback_received()  throws {
        // Given
        let viewModel = LegacyProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                            productName: "Pen",
                                                            productDescription: nil,
                                                            productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                            weightUnit: "kg",
                                                            dimensionUnit: "m",
                                                            stores: stores,
                                                            storageManager: storage,
                                                            analytics: analytics,
                                                            onProductCreated: { _ in })

        // When
        viewModel.handleFeedback(.up)

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_ai_feedback"}))
        let eventProperties = analyticsProvider.receivedProperties[index]
        XCTAssertEqual(eventProperties["source"] as? String, "product_creation")
        XCTAssertEqual(eventProperties["is_useful"] as? Bool, true)
    }
}

private extension LegacyProductDetailPreviewViewModelTests {
    func mockSettingActions() {
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .synchronizeGeneralSiteSettings(_, completion):
                completion(nil)
            case let .synchronizeProductSiteSettings(_, completion):
                completion(nil)
            default:
                break
            }
        }
    }

    func mockProductCategoryActions() {
        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .synchronizeProductCategories(_, _, completion):
                completion(nil)
            case let .addProductCategories(_, _, _, completion):
                completion(.success([]))
            default:
                break
            }
        }
    }

    func mockProductTagActions() {
        stores.whenReceivingAction(ofType: ProductTagAction.self) { action in
            switch action {
            case let .synchronizeAllProductTags(_, completion):
                completion(nil)
            default:
                break
            }
        }
    }

    func mockProductActions(identifiedLanguage: String = "en",
                            aiGeneratedProductResult: Result<AIProduct, Error> = .success(.fake()),
                            addedProductResult: Result<Product, ProductUpdateError> = .success(.fake())) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateAIProduct(_, _, _, _, _, _, _, _, _, _, completion):
                completion(aiGeneratedProductResult)
            case let .identifyLanguage(_, _, _, completion):
                completion(.success(identifiedLanguage))
            case let .addProduct(_, onCompletion):
                onCompletion(addedProductResult)
            default:
                break
            }
        }
    }
}
