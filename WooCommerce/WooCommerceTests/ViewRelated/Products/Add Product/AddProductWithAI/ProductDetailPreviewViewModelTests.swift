import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class ProductDetailPreviewViewModelTests: XCTestCase {
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    // MARK: `generateProductDetails`

    func test_generateProductDetails_sends_name_and_features_to_identify_language() async throws {
        // Given
        let siteID: Int64 = 123

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: siteID))

        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.casual.rawValue]

        let productName = "Pen"
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: productName,
                                                      productDescription: nil,
                                                      productFeatures: productFeatures,
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })
        XCTAssertFalse(viewModel.isGeneratingDetails)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                completion(.success(Product.fake()))
            case let .identifyLanguage(_, string, _, completion):
                // Then
                XCTAssertEqual(string, productName + " " + productFeatures)
                completion(.success("en"))
            default:
                break
            }
        }

        // When
        await viewModel.generateProductDetails()
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

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.sessionManager.setStoreId(sampleSiteID)

        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: sampleSiteID))

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

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
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
            case let  .generateProduct(siteID,
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
                completion(.success(Product.fake()))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success(sampleLanguage))
            default:
                break
            }
        }

        // When
        await viewModel.generateProductDetails()
    }

    func test_generateProductDetails_sends_productDescription_if_available_to_generate_product_details() async throws {
        // Given
        let sampleSiteID: Int64 = 123
        let sampleProductName = "Pen"
        let sampleProductDescription = "Ballpoint, Blue ink, ABS plastic"

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.sessionManager.setStoreId(sampleSiteID)

        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: sampleSiteID))

        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productName: sampleProductName,
                                                      productDescription: sampleProductDescription,
                                                      productFeatures: nil,
                                                      stores: stores,
                                                      storageManager: storage,
                                                      userDefaults: userDefaults,
                                                      onProductCreated: { _ in })
        XCTAssertFalse(viewModel.isGeneratingDetails)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, keywords, _, _, _, _, _, _, _, completion):
                // Then
                XCTAssertEqual(keywords, sampleProductDescription)
                completion(.success(Product.fake()))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }

        // When
        await viewModel.generateProductDetails()
    }

    func test_generateProductDetails_updates_generationInProgress_correctly() async throws {
        // Given
        let siteID: Int64 = 123

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: siteID))

        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.casual.rawValue]

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: "Pen",
                                                      productDescription: nil,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })
        XCTAssertFalse(viewModel.isGeneratingDetails)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                XCTAssertTrue(viewModel.isGeneratingDetails)
                completion(.success(Product.fake()))
            case let .identifyLanguage(_, _, _, completion):
                XCTAssertTrue(viewModel.isGeneratingDetails)
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()

        // Then
        XCTAssertFalse(viewModel.isGeneratingDetails)
    }

    func test_errorState_is_updated_when_generateProductDetails_fails() async throws {
        // Given
        let siteID: Int64 = 123

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: siteID))

        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.casual.rawValue]

        let expectedError = NSError(domain: "test", code: 503)

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: "Pen",
                                                      productDescription: nil,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })
        XCTAssertEqual(viewModel.errorState, .none)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
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
        let product = Product.fake()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: siteID))

        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.casual.rawValue]

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: "Pen",
                                                      productDescription: nil,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                completion(.success(product))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()

        // Then
        XCTAssertEqual(product, viewModel.generatedProduct)
    }

    // MARK: - Save product

    func test_saveProductAsDraft_updates_isSavingProduct_properly() async {
        // Given
        let expectedProduct = Product.fake().copy(name: "iPhone 15")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: "iPhone 15",
                                                      productDescription: nil,
                                                      productFeatures: "",
                                                      stores: stores,
                                                      onProductCreated: { _ in })

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                XCTAssertFalse(viewModel.isSavingProduct)
                completion(.success(expectedProduct))
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
        let expectedProduct = Product.fake().copy(name: "iPhone 15")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: "iPhone 15",
                                                      productDescription: nil,
                                                      productFeatures: "",
                                                      stores: stores,
                                                      onProductCreated: { createdProduct = $0 })

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                completion(.success(expectedProduct))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            case let .addProduct(_, onCompletion):
                onCompletion(.success(expectedProduct))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertEqual(createdProduct, expectedProduct)
    }

    func test_saveProductAsDraft_updates_errorState_upon_failure() async {
        // Given
        let expectedProduct = Product.fake().copy(name: "iPhone 15")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: "iPhone 15",
                                                      productDescription: nil,
                                                      productFeatures: "",
                                                      stores: stores,
                                                      onProductCreated: { _ in })
        XCTAssertEqual(viewModel.errorState, .none)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                completion(.success(expectedProduct))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            case let .addProduct(_, onCompletion):
                onCompletion(.failure(.unexpected))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertEqual(viewModel.errorState, .savingProduct)
    }

    // MARK: Analytics

    func test_generateProductDetails_tracks_event_on_success() async throws {
        // Given
        let siteID: Int64 = 123

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: siteID))

        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.casual.rawValue]

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: "Pen",
                                                      productDescription: nil,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      analytics: analytics,
                                                      onProductCreated: { _ in })

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                completion(.success(Product.fake()))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_generate_product_details_success"))
    }

    func test_generateProductDetails_tracks_event_on_failure() async throws {
        // Given
        let siteID: Int64 = 123

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: siteID))

        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.casual.rawValue]

        let expectedError = NSError(domain: "test", code: 503)

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productName: "Pen",
                                                      productDescription: nil,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      analytics: analytics,
                                                      onProductCreated: { _ in })

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                completion(.failure(expectedError))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_generate_product_details_failed"))

        let errorEventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_creation_ai_generate_product_details_failed"}))
        let errorEventProperties = analyticsProvider.receivedProperties[errorEventIndex]
        XCTAssertEqual(errorEventProperties["error_code"] as? String, "503")
        XCTAssertEqual(errorEventProperties["error_domain"] as? String, "test")
    }
}
