import XCTest
import Yosemite

@testable import WooCommerce

final class ProductFormRemoteActionUseCaseTests: XCTestCase {
    typealias ResultData = ProductFormRemoteActionUseCase.ResultData
    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
    }

    override func tearDown() {
        storesManager = nil
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
        XCTAssertEqual(storesManager.receivedActions.count, 2)
        XCTAssertNotNil(storesManager.receivedActions[0] as? ProductAction)
        XCTAssertNotNil(storesManager.receivedActions[1] as? SitePostAction)
        XCTAssertEqual(result, .success(ResultData(product: model, password: password)))
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
        XCTAssertEqual(storesManager.receivedActions.count, 2)
        XCTAssertNotNil(storesManager.receivedActions[0] as? ProductAction)
        XCTAssertNotNil(storesManager.receivedActions[1] as? SitePostAction)
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
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        XCTAssertNotNil(storesManager.receivedActions.first as? ProductAction)
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
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        XCTAssertNotNil(storesManager.receivedActions.first as? ProductAction)
        XCTAssertEqual(result, .failure(.invalidSKU))
    }

    // MARK: - Editing a product (`addProduct`)

    func test_editing_product_and_password_without_edits_does_not_trigger_actions_and_returns_success_result() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let password = "wo0oo!"
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
        XCTAssertEqual(storesManager.receivedActions.count, 0)
        XCTAssertEqual(result, .success(ResultData(product: model, password: password)))
    }

    func test_editing_product_with_a_password_successfully_returns_success_result() {
        // Arrange
        let originalProduct = Product.fake()
        let product = originalProduct.copy(name: "PRODUCT")
        let originalModel = EditableProductModel(product: originalProduct)
        let model = EditableProductModel(product: product)
        let originalPassword: String? = nil
        let password = "wo0oo!"
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
        XCTAssertEqual(storesManager.receivedActions.count, 2)
        XCTAssertNotNil(storesManager.receivedActions[0] as? ProductAction)
        XCTAssertNotNil(storesManager.receivedActions[1] as? SitePostAction)
        XCTAssertEqual(result, .success(ResultData(product: model, password: password)))
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
        XCTAssertEqual(storesManager.receivedActions.count, 2)
        XCTAssertNotNil(storesManager.receivedActions[0] as? ProductAction)
        XCTAssertNotNil(storesManager.receivedActions[1] as? SitePostAction)
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
        XCTAssertEqual(storesManager.receivedActions.count, 2)
        XCTAssertNotNil(storesManager.receivedActions[0] as? ProductAction)
        XCTAssertNotNil(storesManager.receivedActions[1] as? SitePostAction)
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
        XCTAssertEqual(storesManager.receivedActions.count, 2)
        XCTAssertNotNil(storesManager.receivedActions[0] as? ProductAction)
        XCTAssertNotNil(storesManager.receivedActions[1] as? SitePostAction)
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
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        XCTAssertNotNil(storesManager.receivedActions[0] as? ProductAction)
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
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        XCTAssertNotNil(storesManager.receivedActions.first as? ProductAction)
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

    func test_duplicating_product_with_a_password_unsuccessfully_returns_failure_result_with_password_error() {
        // Given
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let password = "wo0oo!"
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        mockAddProduct(result: .success(product))
        mockUpdatePassword(result: .failure(NSError(domain: "", code: 100, userInfo: nil)))

        // When
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: model, password: password) { aResult in
            result = aResult
        }

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 2)
        XCTAssertNotNil(storesManager.receivedActions[0] as? ProductAction)
        XCTAssertNotNil(storesManager.receivedActions[1] as? SitePostAction)
        XCTAssertEqual(result, .failure(.passwordCannotBeUpdated))
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
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        XCTAssertNotNil(storesManager.receivedActions.first as? ProductAction)
        XCTAssertEqual(result, .success(ResultData(product: model, password: nil)))
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
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        XCTAssertNotNil(storesManager.receivedActions.first as? ProductAction)
        XCTAssertEqual(result, .failure(.invalidSKU))
    }

    func test_duplicating_variable_product_triggers_retrieving_original_product_variations_and_creating_new_variations_for_duplicated_product() {
        // Given
        let testVariationIDs: [Int64] = [11, 20, 35]
        let product = Product.fake().copy(productID: 2, productTypeKey: ProductType.variable.rawValue, variations: testVariationIDs)
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
                let fakeVariation = ProductVariation.fake().copy(productVariationID: Int64.random(in: 99..<999))
                onCompletion(.success(fakeVariation))
            default:
                break
            }
        }

        let copiedProduct = product.copy(productID: 13)
        let finalProduct = copiedProduct.copy(variations: testVariationIDs)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .addProduct(_, let onCompletion):
                onCompletion(.success(copiedProduct))
            case .retrieveProduct(_, _, let onCompletion):
                onCompletion(.success(finalProduct))
            default:
                break
            }
        }

        // When
        let useCase = ProductFormRemoteActionUseCase(stores: storesManager)
        var result: Result<ResultData, ProductUpdateError>?
        useCase.duplicateProduct(originalProduct: model, password: nil) { aResult in
            result = aResult
        }
        waitUntil {
            createdVariationCount == 3
        }

        // Then
        XCTAssertEqual(retrievedVariationIDs, testVariationIDs)
        XCTAssertEqual(result?.isSuccess, true)
    }
}

private extension ProductFormRemoteActionUseCaseTests {
    func mockAddProduct(result: Result<Product, ProductUpdateError>) {
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.addProduct(_, onCompletion) = action {
                onCompletion(result)
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
