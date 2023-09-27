import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class ProductDetailPreviewViewModelTests: XCTestCase {
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

    func test_errorMessage_is_updated_when_generateProductDetails_fails() async throws {
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

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProduct(_, _, _, _, _, _, _, _, _, _, completion):
                XCTAssertNil(viewModel.errorMessage)
                completion(.failure(expectedError))
            case let .identifyLanguage(_, _, _, completion):
                XCTAssertNil(viewModel.errorMessage)
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductDetails()

        // Then
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription)
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
}
