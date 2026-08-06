import XCTest
import Yosemite
import protocol WooFoundation.Analytics

import YosemiteTestHelpers
@testable import WooCommerce

final class ProductFormRemoteActionUseCaseTests: XCTestCase {
    typealias ResultData = ProductFormRemoteActionUseCase.ResultData
    private var storesManager: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var originalAnalytics: Analytics!
    private let siteID: Int64 = 123
    private let pluginName = "WooCommerce"
    private let pluginSlug = "woocommerce"

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
        storesManager.sessionManager.setStoreId(siteID)
        storageManager = MockStorageManager()
        originalAnalytics = ServiceLocator.analytics
        analyticsProvider = MockAnalyticsProvider()
        ServiceLocator.setAnalytics(WooAnalytics(analyticsProvider: analyticsProvider))
    }

    override func tearDown() {
        storesManager = nil
        storageManager = nil
        ServiceLocator.setAnalytics(originalAnalytics)
        analyticsProvider = nil
        originalAnalytics = nil
        super.tearDown()
    }

    // MARK: - Adding a product (`addProduct`)

    func test_adding_product_with_a_password_successfully_returns_success_result() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let password = "wo0oo!"
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockAddProduct(result: .success(product))
        mockUpdatePassword(result: .success(password))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        useCase.addProduct(product: model, password: password) { aResult in
            result = aResult
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .success(ResultData(product: model, password: password)))
        XCTAssertEqual(analyticsProvider.receivedEvents.filter { $0 == WooAnalyticsStat.addProductSuccess.rawValue },
                       [WooAnalyticsStat.addProductSuccess.rawValue])
    }

    func test_adding_product_with_a_password_unsuccessfully_returns_failure_result_with_password_error() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let password = "wo0oo!"
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockAddProduct(result: .success(product))
        mockUpdatePassword(result: .failure(NSError(domain: "", code: 100, userInfo: nil)))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        useCase.addProduct(product: model, password: password) { aResult in
            result = aResult
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .failure(.passwordCannotBeUpdated))
    }

    func test_adding_product_without_a_password_successfully_does_not_trigger_password_action_and_returns_success_result() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockAddProduct(result: .success(product))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        useCase.addProduct(product: model, password: nil) { aResult in
            result = aResult
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .success(ResultData(product: model, password: nil)))
    }

    func test_adding_product_unsuccessfully_does_not_trigger_password_action_and_returns_failure_result_with_product_error() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        mockAddProduct(result: .failure(.invalidSKU))
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        useCase.addProduct(product: model, password: nil) { aResult in
            result = aResult
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .failure(.invalidSKU))
        XCTAssertEqual(analyticsProvider.receivedEvents.filter { $0 == WooAnalyticsStat.addProductFailed.rawValue },
                       [WooAnalyticsStat.addProductFailed.rawValue])
    }

    // MARK: - Editing a product (`addProduct`)
    func test_editing_product_and_password_without_edits_in_Woo_8_1_and_above_does_not_trigger_actions_and_returns_success_result() {
        // Arrange
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID,
                                                    plugin: pluginSlug,
                                                    name: pluginName,
                                                    version: "9.0",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)
        let password = "wo0oo!"
        let product = Product.fake().copy(password: password)
        let model = EditableProductModel(product: product)
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        waitForExpectation { expectation in
            useCase.editProduct(product: model,
                                originalProduct: model,
                                password: password,
                                originalPassword: password) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertTrue(ProductPasswordEligibilityUseCase(stores: storesManager, storageManager: storageManager).isEligibleForWooProductPasswordEndpoint())
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .success(ResultData(product: model, password: password)))
    }

    func test_editing_product_and_password_without_edits_in_Woo_below_8_1_does_not_trigger_actions_and_returns_success_result() {
        // Arrange
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID,
                                                    plugin: pluginSlug,
                                                    name: pluginName,
                                                    version: "8.0",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)
        let password = "wo0oo!"
        let product = Product.fake().copy(password: password)
        let model = EditableProductModel(product: product)
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        waitForExpectation { expectation in
            useCase.editProduct(product: model,
                                originalProduct: model,
                                password: password,
                                originalPassword: password) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertFalse(ProductPasswordEligibilityUseCase(stores: storesManager, storageManager: storageManager).isEligibleForWooProductPasswordEndpoint())
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .success(ResultData(product: model, password: password)))
    }

    func test_editing_product_with_a_password_in_Woo_8_1_and_above_successfully_returns_success_result() {
        // Arrange
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID,
                                                    plugin: pluginSlug,
                                                    name: pluginName,
                                                    version: "9.0",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)
        let password = "wo0oo!"
        let originalProduct = Product.fake()
        let product = originalProduct.copy(name: "PRODUCT")
        let originalModel = EditableProductModel(product: originalProduct)
        let model = EditableProductModel(product: product.copy(password: password))
        let originalPassword: String? = nil
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockUpdateProduct(result: .success(product))
        mockUpdatePassword(result: .success(password))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        waitForExpectation { expectation in
            useCase.editProduct(product: model,
                                originalProduct: originalModel,
                                password: password,
                                originalPassword: originalPassword) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertTrue(ProductPasswordEligibilityUseCase(stores: storesManager, storageManager: storageManager).isEligibleForWooProductPasswordEndpoint())
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        if case .success(let resultData) = result {
                XCTAssertEqual(resultData.product, model)
            XCTAssertEqual(resultData.password, password)
            } else {
                XCTFail("Expected success but got \(String(describing: result))")
            }
    }

    func test_editing_product_with_a_password_in_Woo_below_8_1_successfully_returns_success_result() {
        // Arrange
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID,
        plugin: pluginSlug,
                                                    name: pluginName,
                                                    version: "8.0",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)
        let password = "wo0oo!"
        let originalProduct = Product.fake()
        let product = originalProduct.copy(name: "PRODUCT")
        let originalModel = EditableProductModel(product: originalProduct)
        let model = EditableProductModel(product: product.copy(password: password))
        let originalPassword: String? = nil
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockUpdateProduct(result: .success(product))
        mockUpdatePassword(result: .success(password))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        waitForExpectation { expectation in
            useCase.editProduct(product: model,
                                originalProduct: originalModel,
                                password: password,
                                originalPassword: originalPassword) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertFalse(ProductPasswordEligibilityUseCase(stores: storesManager, storageManager: storageManager).isEligibleForWooProductPasswordEndpoint())
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        if case .success(let resultData) = result {
                XCTAssertEqual(resultData.product, model)
            XCTAssertEqual(resultData.password, password)
            } else {
                XCTFail("Expected success but got \(String(describing: result))")
            }
    }

    func test_editing_product_successfully_with_a_password_unsuccessfully_returns_failure_result_with_password_error() {
        // Arrange
        let originalProduct = Product.fake()
        let product = originalProduct.copy(name: "PRODUCT")
        let originalModel = EditableProductModel(product: originalProduct)
        let model = EditableProductModel(product: product)
        let originalPassword: String? = nil
        let password = "wo0oo!"
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockUpdateProduct(result: .success(product))
        mockUpdatePassword(result: .failure(NSError(domain: "", code: 100, userInfo: nil)))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        waitForExpectation { expectation in
            useCase.editProduct(product: model,
                                originalProduct: originalModel,
                                password: password,
                                originalPassword: originalPassword) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .failure(.passwordCannotBeUpdated))
    }

    func test_editing_product_unsuccessfully_with_a_password_successfully_returns_failure_result_with_product_error() {
        // Arrange
        let originalProduct = Product.fake()
        let product = originalProduct.copy(name: "PRODUCT")
        let originalModel = EditableProductModel(product: originalProduct)
        let model = EditableProductModel(product: product)
        let originalPassword: String? = nil
        let password = "wo0oo!"
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockUpdateProduct(result: .failure(.invalidSKU))
        mockUpdatePassword(result: .success(password))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        waitForExpectation { expectation in
            useCase.editProduct(product: model,
                                originalProduct: originalModel,
                                password: password,
                                originalPassword: originalPassword) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .failure(.invalidSKU))
    }

    func test_editing_product_unsuccessfully_with_a_password_unsuccessfully_returns_failure_result_with_product_error() {
        // Arrange
        let originalProduct = Product.fake()
        let product = originalProduct.copy(name: "PRODUCT")
        let originalModel = EditableProductModel(product: originalProduct)
        let model = EditableProductModel(product: product)
        let originalPassword: String? = nil
        let password = "wo0oo!"
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockUpdateProduct(result: .failure(.invalidSKU))
        mockUpdatePassword(result: .failure(NSError(domain: "", code: 100, userInfo: nil)))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        waitForExpectation { expectation in
            useCase.editProduct(product: model,
                                originalProduct: originalModel,
                                password: password,
                                originalPassword: originalPassword) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .failure(.invalidSKU))
    }

    // MARK: - Delete a product (`deleteProduct`)

    func test_deleting_product_successfully_returns_success_result() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockDeleteProduct(result: .success(product))

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        useCase.deleteProduct(product: model) { aResult in
            result = aResult
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .success(ResultData(product: model, password: nil)))
    }

    func test_deleting_product_returns_failure_result_with_product_error() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        mockDeleteProduct(result: .failure(.unexpected))
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // Action
        var result: Result<ResultData, ProductUpdateError>?
        useCase.deleteProduct(product: model) { aResult in
            result = aResult
        }

        // Assert
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .failure(.unexpected))
    }

    // MARK: - Duplicate a product (`duplicateProduct`)
    func test_duplicating_product_triggers_adding_copy_of_product_correctly() {
        // Given
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.published.rawValue, sku: "12356")
        let model = EditableProductModel(product: product)
        var copiedProductName: String?
        var copiedProductStatusKey: String?
        var copiedProductSKU: String?
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // When
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .duplicateProduct(_, _, let onCompletion):
                onCompletion(.failure(.endpointUnavailable))
            case .addProduct(let product, _):
                copiedProductName = product.name
                copiedProductStatusKey = product.statusKey
                copiedProductSKU = product.sku
            default:
                break
            }
        }
        useCase.duplicateProduct(originalProduct: model, password: nil, onCompletion: { _ in })

        // Then
        assertEqual(String(format: Localization.copyProductName, product.name), copiedProductName)
        assertEqual(ProductStatus.draft.rawValue, copiedProductStatusKey)
        XCTAssertNil(copiedProductSKU)
    }

    func test_duplicating_product_clears_slug_so_server_assigns_a_unique_one() {
        // Given
        // Reusing the source slug in the create request risks the storefront resolving to the
        // original product, so the duplicate must be created with an empty slug for the server
        // to assign a unique one.
        let product = Product.fake().copy(slug: "original-slug", permalink: "https://store.example/original-slug")
        let model = EditableProductModel(product: product)
        var copiedProductSlug: String?
        var copiedProductPermalink: String?
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // When
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .duplicateProduct(_, _, let onCompletion):
                onCompletion(.failure(.endpointUnavailable))
            case .addProduct(let product, _):
                copiedProductSlug = product.slug
                copiedProductPermalink = product.permalink
            default:
                break
            }
        }
        useCase.duplicateProduct(originalProduct: model, password: nil, onCompletion: { _ in })

        // Then
        assertEqual("", copiedProductSlug)
        assertEqual("", copiedProductPermalink)
        // The source product is never mutated when building the duplicate.
        assertEqual("original-slug", product.slug)
        assertEqual("https://store.example/original-slug", product.permalink)
    }

    func test_duplicating_product_with_a_password_unsuccessfully_returns_failure_result_with_password_error() {
        // Given
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let password = "wo0oo!"
        let passwordError = NSError(domain: "PasswordUpdate", code: 100)
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockAddProduct(result: .success(product))
        mockUpdatePassword(result: .failure(passwordError))

        // When
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: model, password: password) { aResult in
            result = aResult
        }

        // Then
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .failure(.passwordCannotBeUpdated))
        XCTAssertEqual(duplicateAnalyticsEvents, [WooAnalyticsStat.duplicateProductFailed.rawValue])
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["error_domain"] as? String, passwordError.domain)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["error_code"] as? String, String(passwordError.code))
    }

    func test_duplicating_product_without_a_password_successfully_does_not_trigger_password_action_and_returns_success_result() {
        // Given
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockAddProduct(result: .success(product))

        // When
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: model, password: nil) { aResult in
            result = aResult
        }

        // Then
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .success(ResultData(product: model, password: nil)))
        XCTAssertEqual(duplicateAnalyticsEvents, [WooAnalyticsStat.duplicateProductSuccess.rawValue])
    }

    func test_duplicating_product_unsuccessfully_does_not_trigger_password_action_and_returns_failure_result_with_product_error() {
        // Given
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        mockAddProduct(result: .failure(.invalidSKU))
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // When
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: model, password: "test") { aResult in
            result = aResult
        }

        // Then
        XCTAssertTrue(storesManager.receivedActions.contains(where: { $0 is ProductAction }))
        XCTAssertFalse(storesManager.receivedActions.contains(where: { $0 is SitePostAction }))
        XCTAssertEqual(result, .failure(.invalidSKU))
        XCTAssertEqual(duplicateAnalyticsEvents, [WooAnalyticsStat.duplicateProductFailed.rawValue])
    }

    func test_duplicating_product_with_custom_fields_dispatches_metadata_update_action() throws {
        // Given
        let customFields = [
            MetaData(metadataID: 1, key: "color", value: "red"),
            MetaData(metadataID: 2, key: "size", value: "large")
        ]
        let product = Product.fake().copy(siteID: siteID, productID: 5, customFields: customFields)
        let model = EditableProductModel(product: product)
        let duplicatedProduct = Product.fake().copy(siteID: siteID, productID: 99)
        mockAddProduct(result: .success(duplicatedProduct))

        var receivedParentItemID: Int64?
        var receivedMetadata: [RequestParameterDictionary]?
        storesManager.whenReceivingAction(ofType: MetaDataAction.self) { action in
            if case let MetaDataAction.updateMetaData(_, parentItemID, _, metadata, onCompletion) = action {
                receivedParentItemID = parentItemID
                receivedMetadata = metadata
                onCompletion(.success([]))
            }
        }

        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // When
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: model, password: nil) { result = $0 }

        // Then
        XCTAssertEqual(receivedParentItemID, 99)
        XCTAssertEqual(receivedMetadata?.count, 2)
        XCTAssertEqual(receivedMetadata?[0]["key"], .string("color"))
        XCTAssertEqual(receivedMetadata?[0]["value"], .string("red"))
        XCTAssertEqual(receivedMetadata?[1]["key"], .string("size"))
        XCTAssertEqual(receivedMetadata?[1]["value"], .string("large"))

        // Verify the returned product optimistically includes custom fields
        let returnedProduct = try XCTUnwrap(result?.get().product)
        XCTAssertEqual(returnedProduct.product.customFields, customFields)
    }

    func test_core_duplicate_fetches_canonical_product_without_dispatching_legacy_copy_actions_for_supported_product_types() throws {
        for productType in [ProductType.simple, .variable, .subscription, .variableSubscription] {
            // Given
            storesManager.reset()
            analyticsProvider.clearEvents()
            let sourceProductID: Int64 = 5
            let duplicatedProductID: Int64 = 99
            let source = Product.fake().copy(siteID: siteID,
                                             productID: sourceProductID,
                                             productTypeKey: productType.rawValue,
                                             variations: [11, 12],
                                             customFields: [MetaData(metadataID: 1, key: "custom_key", value: "source_value")])
            let canonicalDuplicate = source.copy(productID: duplicatedProductID,
                                                 name: "Server Copy",
                                                 slug: "server-copy",
                                                 permalink: "https://example.com/product/server-copy")
            storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
                switch action {
                case let .duplicateProduct(receivedSiteID, receivedProductID, onCompletion):
                    XCTAssertEqual(receivedSiteID, self.siteID)
                    XCTAssertEqual(receivedProductID, sourceProductID)
                    onCompletion(.success(duplicatedProductID))
                case let .retrieveProduct(receivedSiteID, receivedProductID, onCompletion):
                    XCTAssertEqual(receivedSiteID, self.siteID)
                    XCTAssertEqual(receivedProductID, duplicatedProductID)
                    XCTAssertTrue(self.duplicateAnalyticsEvents.isEmpty)
                    onCompletion(.success(canonicalDuplicate))
                case .addProduct:
                    XCTFail("Core duplication must not create a second product with the legacy endpoint")
                default:
                    break
                }
            }
            let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

            // When
            var result: Result<ResultData, ProductUpdateError>?
            useCase.duplicateProduct(originalProduct: EditableProductModel(product: source), password: "secret") {
                result = $0
            }

            // Then
            let resultData = try XCTUnwrap(result?.get())
            XCTAssertEqual(resultData.product, EditableProductModel(product: canonicalDuplicate))
            XCTAssertEqual(resultData.password, "secret")
            XCTAssertEqual(storesManager.receivedActions.compactMap { $0 as? ProductAction }.count, 2)
            XCTAssertFalse(storesManager.receivedActions.contains { $0 is MetaDataAction })
            XCTAssertFalse(storesManager.receivedActions.contains { $0 is ProductVariationAction })
            XCTAssertFalse(storesManager.receivedActions.contains { $0 is SitePostAction })
            XCTAssertEqual(duplicateAnalyticsEvents, [WooAnalyticsStat.duplicateProductSuccess.rawValue])
        }
    }

    func test_core_duplicate_failure_is_terminal_and_does_not_run_legacy_fallback() {
        // Given
        let underlyingError = NSError(domain: "ProductDuplicate", code: 500)
        let product = Product.fake().copy(siteID: siteID, productID: 5)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, _, onCompletion):
                onCompletion(.failure(.unknown(error: AnyError(underlyingError))))
            case .addProduct, .retrieveProduct:
                XCTFail("Ambiguous duplication failures must not trigger another product request")
            default:
                break
            }
        }
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // When
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: EditableProductModel(product: product), password: nil) {
            result = $0
        }

        // Then
        XCTAssertEqual(result, .failure(.unknown(error: AnyError(underlyingError))))
        XCTAssertEqual(storesManager.receivedActions.compactMap { $0 as? ProductAction }.count, 1)
        XCTAssertEqual(duplicateAnalyticsEvents, [WooAnalyticsStat.duplicateProductFailed.rawValue])
    }

    func test_core_duplicate_canonical_retrieval_failure_is_terminal_and_does_not_run_legacy_fallback() {
        // Given
        let underlyingError = NSError(domain: "ProductRetrieve", code: 500)
        let product = Product.fake().copy(siteID: siteID, productID: 5)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, _, onCompletion):
                onCompletion(.success(99))
            case let .retrieveProduct(_, _, onCompletion):
                onCompletion(.failure(underlyingError))
            case .addProduct:
                XCTFail("A failed canonical fetch after duplication must not create another product")
            default:
                break
            }
        }
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // When
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: EditableProductModel(product: product), password: nil) {
            result = $0
        }

        // Then
        XCTAssertEqual(result, .failure(.unknown(error: AnyError(underlyingError))))
        XCTAssertEqual(storesManager.receivedActions.compactMap { $0 as? ProductAction }.count, 2)
        XCTAssertEqual(duplicateAnalyticsEvents, [WooAnalyticsStat.duplicateProductFailed.rawValue])
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["error_domain"] as? String, underlyingError.domain)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["error_code"] as? String, String(underlyingError.code))
    }

    func test_legacy_fallback_preserves_images_and_does_not_mutate_subscription_source_product() throws {
        // Given
        let images = [ProductImage(imageID: 12,
                                   dateCreated: Date(),
                                   dateModified: Date(),
                                   src: "https://example.com/source.jpg",
                                   name: "source",
                                   alt: "Source image")]
        let source = Product.fake().copy(siteID: siteID,
                                         productID: 5,
                                         slug: "source-product",
                                         permalink: "https://example.com/product/source-product",
                                         productTypeKey: ProductType.subscription.rawValue,
                                         images: images)
        let sourceModel = EditableProductModel(product: source)
        var submittedProduct: Product?
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, _, onCompletion):
                onCompletion(.failure(.endpointUnavailable))
            case let .addProduct(product, onCompletion):
                submittedProduct = product
                onCompletion(.success(product.copy(productID: 99)))
            default:
                break
            }
        }
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)

        // When
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: sourceModel, password: nil) {
            result = $0
        }

        // Then
        XCTAssertEqual(submittedProduct?.images, images)
        XCTAssertEqual(submittedProduct?.slug, "")
        XCTAssertEqual(submittedProduct?.permalink, "")
        XCTAssertEqual(sourceModel, EditableProductModel(product: source))
        XCTAssertEqual(try result?.get().product.product.images, images)
    }

    func test_legacy_fallback_for_variable_product_types_recreates_variations() {
        for productType in [ProductType.variable, .variableSubscription] {
            assertLegacyFallbackRecreatesVariations(for: productType)
        }
    }

    func test_legacy_fallback_variable_product_failure_tracks_one_failure_only_after_final_retrieval_fails() {
        // Given
        let variationID: Int64 = 11
        let source = Product.fake().copy(siteID: siteID,
                                         productID: 2,
                                         productTypeKey: ProductType.variable.rawValue,
                                         variations: [variationID])
        let copiedProduct = source.copy(productID: 13)
        let retrievalError = NSError(domain: "ProductRetrieve", code: 500)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .retrieveProductVariation(_, _, _, onCompletion):
                onCompletion(.success(ProductVariation.fake().copy(productVariationID: variationID)))
            case let .createProductVariation(_, _, _, onCompletion):
                onCompletion(.success(ProductVariation.fake().copy(productVariationID: 99)))
            default:
                break
            }
        }
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, _, onCompletion):
                onCompletion(.failure(.endpointUnavailable))
            case let .addProduct(_, onCompletion):
                onCompletion(.success(copiedProduct))
            case let .retrieveProduct(_, _, onCompletion):
                XCTAssertTrue(self.duplicateAnalyticsEvents.isEmpty)
                onCompletion(.failure(retrievalError))
            default:
                break
            }
        }

        // When
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: EditableProductModel(product: source), password: nil) {
            result = $0
        }
        waitUntil { result != nil }

        // Then
        XCTAssertEqual(result, .failure(.unknown(error: AnyError(retrievalError))))
        XCTAssertEqual(duplicateAnalyticsEvents, [WooAnalyticsStat.duplicateProductFailed.rawValue])
    }
}

private extension ProductFormRemoteActionUseCaseTests {
    func assertLegacyFallbackRecreatesVariations(for productType: ProductType) {
        // Given
        analyticsProvider.clearEvents()
        let testVariationIDs: [Int64] = [11, 20, 35]
        let product = Product.fake().copy(productID: 2, productTypeKey: productType.rawValue, variations: testVariationIDs)
        let model = EditableProductModel(product: product)

        var retrievedVariationIDs: [Int64] = []
        var createdVariationCount = 0
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .retrieveProductVariation(_, _, variationID, onCompletion):
                retrievedVariationIDs.append(variationID)
                onCompletion(.success(ProductVariation.fake().copy(productVariationID: variationID)))
            case let .createProductVariation(_, _, _, onCompletion):
                createdVariationCount += 1
                onCompletion(.success(ProductVariation.fake().copy(productVariationID: Int64.random(in: 99..<999))))
            default:
                break
            }
        }

        let copiedProduct = product.copy(productID: 13)
        let finalProduct = copiedProduct.copy(variations: testVariationIDs)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, _, onCompletion):
                onCompletion(.failure(.endpointUnavailable))
            case let .addProduct(_, onCompletion):
                onCompletion(.success(copiedProduct))
            case let .retrieveProduct(_, _, onCompletion):
                XCTAssertTrue(self.duplicateAnalyticsEvents.isEmpty)
                onCompletion(.success(finalProduct))
            default:
                break
            }
        }

        // When
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: model, password: nil) {
            result = $0
        }
        waitUntil {
            createdVariationCount == testVariationIDs.count && result != nil
        }

        // Then
        XCTAssertEqual(retrievedVariationIDs.sorted(), testVariationIDs.sorted())
        XCTAssertEqual(result?.isSuccess, true)
        XCTAssertEqual(duplicateAnalyticsEvents, [WooAnalyticsStat.duplicateProductSuccess.rawValue])
    }

    var duplicateAnalyticsEvents: [String] {
        analyticsProvider.receivedEvents.filter {
            $0 == WooAnalyticsStat.duplicateProductSuccess.rawValue || $0 == WooAnalyticsStat.duplicateProductFailed.rawValue
        }
    }

    func mockAddProduct(result: Result<Product, ProductUpdateError>) {
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, _, onCompletion):
                onCompletion(.failure(.endpointUnavailable))
            case let .addProduct(_, onCompletion):
                onCompletion(result)
            default:
                break
            }
        }
    }

    func mockUpdateProduct(result: Result<Product, ProductUpdateError>) {
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.updateProduct(_, onCompletion) = action {
                onCompletion(result)
            }
        }
    }

    func mockDeleteProduct(result: Result<Product, ProductUpdateError>) {
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.deleteProduct(_, _, onCompletion) = action {
                onCompletion(result)
            }
        }
    }

    func mockUpdatePassword(result: Result<String?, Error>) {
        storesManager.whenReceivingAction(ofType: SitePostAction.self) { action in
            if case let SitePostAction.updateSitePostPassword(_, _, _, onCompletion) = action {
                onCompletion(result)
            }
        }
    }
}


private extension ProductFormRemoteActionUseCaseTests {
    enum Localization {
        static let copyProductName = NSLocalizedString(
            "%1$@ Copy",
            comment: "The default name for a duplicated product, with %1$@ being the original name. Reads like: Ramen Copy"
        )
    }
}
