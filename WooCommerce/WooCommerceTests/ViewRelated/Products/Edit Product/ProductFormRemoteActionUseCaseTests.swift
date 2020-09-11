import XCTest
import Yosemite

@testable import WooCommerce

final class ProductFormRemoteActionUseCaseTests: XCTestCase {
    typealias ResultData = ProductFormRemoteActionUseCase.ResultData
    private var storesManager: MockupStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockupStoresManager(sessionManager: SessionManager.testingInstance)
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    // MARK: - Adding a product (`addProduct`)

    func test_adding_product_with_a_password_successfully_returns_success_result() {
        // Arrange
        let product = MockProduct().product()
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
        let product = MockProduct().product()
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
        let product = MockProduct().product()
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
        let product = MockProduct().product()
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
        let product = MockProduct().product()
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
        let originalProduct = MockProduct().product()
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
        let originalProduct = MockProduct().product()
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
        let originalProduct = MockProduct().product()
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
        let originalProduct = MockProduct().product()
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

    func mockUpdatePassword(result: Result<String?, Error>) {
        storesManager.whenReceivingAction(ofType: SitePostAction.self) { action in
            if case let SitePostAction.updateSitePostPassword(_, _, _, onCompletion) = action {
                onCompletion(result)
            }
        }
    }
}
