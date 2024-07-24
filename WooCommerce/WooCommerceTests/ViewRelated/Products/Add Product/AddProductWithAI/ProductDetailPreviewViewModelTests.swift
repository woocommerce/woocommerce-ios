import XCTest
@testable import Yosemite
@testable import WooCommerce
import WooFoundation
import class Photos.PHAsset

final class ProductDetailPreviewViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 123
    private static let sampleNames = ["Pen", "Elegant Fountain Pen", "Good Pen"]
    private static let sampleDescriptions = ["Description", "Description 1", "Description 2"]
    private static let sampleShortDescriptions = ["Short description", "Short description 1", "Short description 2"]
    private let sampleAIProduct = AIProduct.fake().copy(names: sampleNames,
                                                        descriptions: sampleDescriptions,
                                                        shortDescriptions: sampleShortDescriptions)
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
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: productFeatures,
                                                      imageState: .empty,
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
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: productFeatures,
                                                      imageState: .empty,
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
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: productFeatures,
                                                      imageState: .empty,
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
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: productFeatures,
                                                      imageState: .empty,
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

    func test_generateProductDetails_sends_features_to_identify_language() async throws {
        // Given
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: productFeatures,
                                                      imageState: .empty,
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
                XCTAssertEqual(string, productFeatures)
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
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"
        let expectedLanguage = "en"
        var identifyingLanguageRequestCount = 0

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: productFeatures,
                                                      imageState: .empty,
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

    func test_categories_are_synced_only_once_when_generating_product_details_again() async {
        // Given
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"
        var syncCategoriesRequestCount = 0

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: productFeatures,
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })

        mockProductActions()
        mockProductTagActions()
        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .synchronizeProductCategories(_, _, completion):
                syncCategoriesRequestCount += 1
                completion(nil)
            case let .addProductCategories(siteID, names, _, completion):
                completion(.success(names.map({ ProductCategory.fake().copy(siteID: siteID, name: $0) })))
            default:
                break
            }
        }

        // When
        await viewModel.generateProductDetails()
        // Retry once
        await viewModel.generateProductDetails()

        // Then
        XCTAssertEqual(syncCategoriesRequestCount, 1)
    }

    func test_tags_are_synced_only_once_when_generating_product_details_again() async {
        // Given
        let productFeatures = "Ballpoint, Blue ink, ABS plastic"
        var syncTagsRequestCount = 0

        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: productFeatures,
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })

        mockProductActions()
        stores.whenReceivingAction(ofType: ProductTagAction.self) { action in
            switch action {
            case let .synchronizeAllProductTags(_, completion):
                syncTagsRequestCount += 1
                completion(nil)
            case let .addProductTags(siteID, tags, completion):
                completion(.success(tags.map({ ProductTag.fake().copy(siteID: siteID, name: $0) })))
            default:
                break
            }
        }
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
        // Retry once
        await viewModel.generateProductDetails()

        // Then
        XCTAssertEqual(syncTagsRequestCount, 1)
    }

    func test_generateProductDetails_sends_correct_values_to_generate_product_details() async throws {
        // Given
        let sampleSiteID: Int64 = 123
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

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: sampleProductFeatures,
                                                      imageState: .empty,
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
                                         _,
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

    func test_generateProductDetails_updates_generationInProgress_correctly() async throws {
        // Given
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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
                completion(.success(self.sampleAIProduct))
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
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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

    func test_generateProductDetails_displays_generatedProduct_correctly() async throws {
        // Given
        let siteID: Int64 = 123
        let names = ["Pen", "Elegant Fountain Pen", "Precision Rollerball Pen"]
        let descriptions = ["Sample description", "Sample description 2", "Sample description 3"]
        let shortDescriptions = ["Sample short description", "Sample short description 2", "Sample short description 3"]
        let virtual = true
        let weight = "21"
        let length = "0.2"
        let width = "0.23"
        let height = "0.24"
        let price = "20"

        let currencySettings = CurrencySettings()
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings) // Defaults to US currency & format

        let aiProduct = AIProduct(names: names,
                                  descriptions: descriptions,
                                  shortDescriptions: shortDescriptions,
                                  virtual: virtual,
                                  shipping: .init(length: length, weight: weight, width: width, height: height),
                                  tags: [],
                                  price: price,
                                  categories: [])

        let viewModel = ProductDetailPreviewViewModel(siteID: siteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      currency: currencySettings.symbol(from: currencySettings.currencyCode),
                                                      currencyFormatter: currencyFormatter,
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
        XCTAssertEqual(viewModel.productName, names.first)
        XCTAssertEqual(viewModel.productDescription, descriptions.first)
        XCTAssertEqual(viewModel.productShortDescription, shortDescriptions.first)
        let productPrice = try XCTUnwrap(viewModel.productPrice)
        XCTAssertTrue(productPrice.contains(price))
        XCTAssertEqual(viewModel.productType, ProductDetailPreviewViewModel.Localization.virtualProductType)
        let weightString = String.localizedStringWithFormat(ProductDetailPreviewViewModel.Localization.weightFormat,
                                                      weight, "kg")
        let dimensionsString = String.localizedStringWithFormat(ProductDetailPreviewViewModel.Localization.fullDimensionsFormat,
                                                          length, width, height, "m")
        XCTAssertEqual(viewModel.productShippingDetails, "\(weightString)\n\(dimensionsString)")
    }

    func test_it_saves_generated_product_correctly() async throws {
        // Given
        let siteID: Int64 = 123
        let names = ["Pen", "Elegant Fountain Pen", "Precision Rollerball Pen"]
        let descriptions = ["Sample description", "Sample description 2", "Sample description 3"]
        let shortDescriptions = ["Sample short description", "Sample short description 2", "Sample short description 3"]
        let virtual = true
        let weight = "0.2"
        let length = "0.2"
        let width = "0.2"
        let height = "0.2"
        let price = "0.2"

        let aiProduct = AIProduct(names: names,
                                  descriptions: descriptions,
                                  shortDescriptions: shortDescriptions,
                                  virtual: virtual,
                                  shipping: .init(length: length, weight: weight, width: width, height: height),
                                  tags: [],
                                  price: price,
                                  categories: [])

        var savedProduct: Product?
        let viewModel = ProductDetailPreviewViewModel(siteID: siteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { product in
            savedProduct = product
        })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        let generatedProduct = try XCTUnwrap(savedProduct)
        XCTAssertEqual(generatedProduct.name, names.first)
        XCTAssertEqual(generatedProduct.fullDescription, descriptions.first)
        XCTAssertEqual(generatedProduct.shortDescription, shortDescriptions.first)
        XCTAssertTrue(generatedProduct.virtual)
        XCTAssertEqual(generatedProduct.dimensions.width, width)
        XCTAssertEqual(generatedProduct.dimensions.height, height)
        XCTAssertEqual(generatedProduct.dimensions.length, length)
        XCTAssertEqual(generatedProduct.weight, weight)
        XCTAssertEqual(generatedProduct.regularPrice, price)
    }

    @MainActor
    func test_saveProductAsDraft_triggers_image_upload_if_there_is_packaging_image() async {
        // Given
        let aiProduct = sampleAIProduct
        let imageState: EditableImageViewState = .success(.init(image: .init(), source: .asset(asset: PHAsset())))

        let productImagesUploader = MockProductImageUploader()
        let expectedImage = ProductImage.fake().copy(imageID: 14324)
        productImagesUploader.whenProductIsSaved(thenReturn: .success([expectedImage]))

        var savedProduct: Product?
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: imageState,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      productImageUploader: productImagesUploader,
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { savedProduct = $0 })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        XCTAssertTrue(productImagesUploader.saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled)
        XCTAssertTrue(productImagesUploader.replaceLocalIDWasCalled)
        XCTAssertEqual(savedProduct?.images, [expectedImage])
    }

    // MARK: Options
    func test_the_options_title_is_based_on_total_options() async throws {
        // Given
        let aiProduct = sampleAIProduct

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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
        XCTAssertEqual(viewModel.optionsTitle, String.localizedStringWithFormat(ProductDetailPreviewViewModel.Localization.OptionSwitch.title,
                                                                                1,
                                                                                3))
    }

    func test_it_switches_between_options() async throws {
        // Given
        let aiProduct = sampleAIProduct

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()
        await viewModel.generateProductDetails()

        XCTAssertEqual(viewModel.productName, Self.sampleNames.first)
        XCTAssertEqual(viewModel.productDescription, Self.sampleDescriptions.first)
        XCTAssertEqual(viewModel.productShortDescription, Self.sampleShortDescriptions.first)

        // When
        viewModel.switchToNextOption()

        // Then
        XCTAssertEqual(viewModel.productName, Self.sampleNames[1])
        XCTAssertEqual(viewModel.productDescription, Self.sampleDescriptions[1])
        XCTAssertEqual(viewModel.productShortDescription, Self.sampleShortDescriptions[1])

        // When
        viewModel.switchToPreviousOption()

        // Then
        XCTAssertEqual(viewModel.productName, Self.sampleNames.first)
        XCTAssertEqual(viewModel.productDescription, Self.sampleDescriptions.first)
        XCTAssertEqual(viewModel.productShortDescription, Self.sampleShortDescriptions.first)
    }

    func test_it_enables_switching_when_there_are_more_than_one_option() async throws {
        // Given
        let aiProduct = sampleAIProduct

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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

        XCTAssertTrue(viewModel.canSwitchBetweenOptions)
    }

    func test_it_hides_switch_when_there_is_only_one_option() async throws {
        // Given
        let aiProduct = AIProduct.fake().copy(names: ["Name"],
                                              descriptions: ["Description"],
                                              shortDescriptions: ["Short description"])

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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

        XCTAssertFalse(viewModel.canSwitchBetweenOptions)
    }

    func test_it_prevents_switching_when_there_are_no_more_options() async throws {
        // Given
        let aiProduct = sampleAIProduct

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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

        XCTAssertTrue(viewModel.canSelectNextOption)
        XCTAssertFalse(viewModel.canSelectPreviousOption)

        // When
        viewModel.switchToNextOption()

        // Then
        XCTAssertTrue(viewModel.canSelectNextOption)
        XCTAssertTrue(viewModel.canSelectPreviousOption)

        // When
        viewModel.switchToNextOption()

        // Then
        XCTAssertFalse(viewModel.canSelectNextOption)
        XCTAssertTrue(viewModel.canSelectPreviousOption)
    }

    // MARK: - Undo edits

    func test_it_tracks_changes_to_text_fields() async throws {
        // Given
        let aiProduct = sampleAIProduct

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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

        XCTAssertFalse(viewModel.hasChangesToProductName)
        XCTAssertFalse(viewModel.hasChangesToProductShortDescription)
        XCTAssertFalse(viewModel.hasChangesToProductDescription)

        // When
        viewModel.productName = "Edited name"

        // Then
        XCTAssertTrue(viewModel.hasChangesToProductName)
        XCTAssertFalse(viewModel.hasChangesToProductShortDescription)
        XCTAssertFalse(viewModel.hasChangesToProductDescription)

        // When
        viewModel.productShortDescription = "Edited short description"

        // Then
        XCTAssertTrue(viewModel.hasChangesToProductName)
        XCTAssertTrue(viewModel.hasChangesToProductShortDescription)
        XCTAssertFalse(viewModel.hasChangesToProductDescription)

        // When
        viewModel.productDescription = "Edited description"

        // Then
        XCTAssertTrue(viewModel.hasChangesToProductName)
        XCTAssertTrue(viewModel.hasChangesToProductShortDescription)
        XCTAssertTrue(viewModel.hasChangesToProductDescription)
    }

    func test_it_undoes_changes_in_name_field() async throws {
        // Given
        let aiProduct = sampleAIProduct

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()
        await viewModel.generateProductDetails()

        // When
        viewModel.productName = "Edited name"
        viewModel.productShortDescription = "Edited short description"
        viewModel.productDescription = "Edited description"

        // Then
        XCTAssertEqual(viewModel.productName, "Edited name")

        // When
        viewModel.undoEdits(in: .name)

        // Then
        XCTAssertEqual(viewModel.productName, Self.sampleNames.first)
        XCTAssertEqual(viewModel.productShortDescription, "Edited short description")
        XCTAssertEqual(viewModel.productDescription, "Edited description")
    }

    func test_it_undoes_changes_in_short_description_field() async throws {
        // Given
        let aiProduct = sampleAIProduct

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()
        await viewModel.generateProductDetails()

        // When
        viewModel.productName = "Edited name"
        viewModel.productShortDescription = "Edited short description"
        viewModel.productDescription = "Edited description"

        // Then
        XCTAssertEqual(viewModel.productShortDescription, "Edited short description")

        // When
        viewModel.undoEdits(in: .shortDescription)

        // Then
        XCTAssertEqual(viewModel.productName, "Edited name")
        XCTAssertEqual(viewModel.productShortDescription, Self.sampleShortDescriptions.first)
        XCTAssertEqual(viewModel.productDescription, "Edited description")
    }

    func test_it_undoes_changes_in_description_field() async throws {
        // Given
        let aiProduct = sampleAIProduct

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { _ in })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()
        await viewModel.generateProductDetails()

        // When
        viewModel.productName = "Edited name"
        viewModel.productShortDescription = "Edited short description"
        viewModel.productDescription = "Edited description"
        // Then
        XCTAssertEqual(viewModel.productDescription, "Edited description")

        // When
        viewModel.undoEdits(in: .description)

        // Then
        XCTAssertEqual(viewModel.productName, "Edited name")
        XCTAssertEqual(viewModel.productShortDescription, "Edited short description")
        XCTAssertEqual(viewModel.productDescription, Self.sampleDescriptions.first)
    }

    // MARK: - Save product

    func test_it_saves_product_with_matching_existing_categories() async throws {
        // Given
        let sampleSiteID: Int64 = 123
        let biscuit = ProductCategory.fake().copy(siteID: sampleSiteID, name: "Biscuits")
        let aiProduct = sampleAIProduct.copy(categories: [biscuit.name])

        let sampleCategories = [biscuit, ProductCategory.fake().copy(siteID: sampleSiteID)]
        sampleCategories.forEach { storage.insertSampleProductCategory(readOnlyProductCategory: $0) }

        let sampleTags = [ProductTag.fake().copy(siteID: sampleSiteID), ProductTag.fake().copy(siteID: sampleSiteID)]
        sampleTags.forEach { storage.insertSampleProductTag(readOnlyProductTag: $0) }

        // Insert categories and tags for other site to test correct items that belong to current site are sent
        storage.insertSampleProductCategory(readOnlyProductCategory: .fake().copy(siteID: 321))
        storage.insertSampleProductTag(readOnlyProductTag: .fake().copy(siteID: 321))

        var savedProduct: Product?
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { product in
            savedProduct = product
        })


        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        let generatedProduct = try XCTUnwrap(savedProduct)
        XCTAssertEqual(generatedProduct.categories, [biscuit])
    }

    func test_it_saves_product_with_new_categories_suggested_by_AI() async throws {
        // Given
        let aiProduct = sampleAIProduct.copy(categories: ["Biscuits", "Cookies"])
        var savedProduct: Product?
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { product in
            savedProduct = product
        })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        let generatedProduct = try XCTUnwrap(savedProduct)
        XCTAssertEqual(generatedProduct.categories.map { $0.name }, ["Biscuits", "Cookies"])
        XCTAssertEqual(generatedProduct.categories.map { $0.categoryID }, [0, 0])
    }

    func test_it_saves_product_with_matching_existing_tags() async throws {
        // Given
        let food: ProductTag = .fake().copy(siteID: sampleSiteID, name: "Food")
        let aiProduct = sampleAIProduct.copy(tags: [food.name])

        let sampleCategories = [ProductCategory.fake().copy(siteID: sampleSiteID), ProductCategory.fake().copy(siteID: sampleSiteID)]
        sampleCategories.forEach { storage.insertSampleProductCategory(readOnlyProductCategory: $0) }

        let sampleTags = [food, ProductTag.fake().copy(siteID: sampleSiteID)]
        sampleTags.forEach { storage.insertSampleProductTag(readOnlyProductTag: $0) }

        // Insert categories and tags for other site to test correct items that belong to current site are sent
        storage.insertSampleProductCategory(readOnlyProductCategory: .fake().copy(siteID: 321))
        storage.insertSampleProductTag(readOnlyProductTag: .fake().copy(siteID: 321))

        var savedProduct: Product?
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { product in
            savedProduct = product
        })

        mockProductActions(aiGeneratedProductResult: .success(aiProduct))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        let generatedProduct = try XCTUnwrap(savedProduct)
        XCTAssertEqual(generatedProduct.tags, [food])
    }

    func test_it_saves_product_with_new_tags_suggested_by_AI() async throws {
        // Given
        let product = sampleAIProduct.copy(tags: ["Food", "Grocery"])
        var savedProduct: Product?
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
                                                      weightUnit: "kg",
                                                      dimensionUnit: "m",
                                                      stores: stores,
                                                      storageManager: storage,
                                                      onProductCreated: { product in
            savedProduct = product
        })

        mockProductActions(aiGeneratedProductResult: .success(product))
        mockProductTagActions()
        mockProductCategoryActions()

        // When
        await viewModel.generateProductDetails()
        await viewModel.saveProductAsDraft()

        // Then
        let generatedProduct = try XCTUnwrap(savedProduct)
        XCTAssertEqual(generatedProduct.tags.map { $0.name }, ["Food", "Grocery"])
        XCTAssertEqual(generatedProduct.tags.map { $0.tagID }, [0, 0])
    }

    func test_saveProductAsDraft_updates_isSavingProduct_properly() async {
        // Given
        let aiProduct = sampleAIProduct.copy(names: ["iPhone 15"])
        let expectedProduct = Product(siteID: 123,
                                      name: "iPhone 15",
                                      fullDescription: "Description",
                                      shortDescription: "Short description",
                                      aiProduct: aiProduct,
                                      categories: [],
                                      tags: [])
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: "",
                                                      imageState: .empty,
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
        let aiProduct = sampleAIProduct
        let expectedProduct = Product(siteID: 123,
                                      name: "iPhone 15",
                                      fullDescription: "Description",
                                      shortDescription: "Short description",
                                      aiProduct: aiProduct,
                                      categories: [],
                                      tags: [])
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: "",
                                                      imageState: .empty,
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
        let aiProduct = sampleAIProduct.copy(names: ["iPhone 15"])
        let viewModel = ProductDetailPreviewViewModel(siteID: 123,
                                                      productFeatures: "",
                                                      imageState: .empty,
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
        let aiProduct = sampleAIProduct.copy(categories: ["Biscuits", "Cookies"])

        let sampleCategories = [grocery]
        sampleCategories.forEach { storage.insertSampleProductCategory(readOnlyProductCategory: $0) }

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "",
                                                      imageState: .empty,
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
        let aiProduct = sampleAIProduct.copy(tags: ["Tag 1", "Tag 2"])

        let sampleTags = [existingTag, ProductTag.fake().copy(siteID: sampleSiteID)]
        sampleTags.forEach { storage.insertSampleProductTag(readOnlyProductTag: $0) }

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "",
                                                      imageState: .empty,
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
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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

        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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
        let viewModel = ProductDetailPreviewViewModel(siteID: sampleSiteID,
                                                      productFeatures: "Ballpoint, Blue ink, ABS plastic",
                                                      imageState: .empty,
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

private extension ProductDetailPreviewViewModelTests {
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
            case let .addProductCategories(siteID, names, _, completion):
                completion(.success(names.map({ ProductCategory.fake().copy(siteID: siteID, name: $0) })))
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
            case let .addProductTags(siteID, tags, completion):
                completion(.success(tags.map({ ProductTag.fake().copy(siteID: siteID, name: $0) })))
            default:
                break
            }
        }
    }

    func mockProductActions(identifiedLanguage: String = "en",
                            aiGeneratedProductResult: (Result<AIProduct, Error>)? = nil,
                            addedProductResult: (Result<Product, ProductUpdateError>)? = nil) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateAIProduct(_, _, _, _, _, _, _, _, _, _, completion):
                if let aiGeneratedProductResult {
                    completion(aiGeneratedProductResult)
                } else {
                    completion(.success(self.sampleAIProduct))
                }
            case let .identifyLanguage(_, _, _, completion):
                completion(.success(identifiedLanguage))
            case let .addProduct(product, onCompletion):
                if let addedProductResult {
                    onCompletion(addedProductResult)
                } else {
                    onCompletion(.success(product))
                }
            default:
                break
            }
        }
    }
}
