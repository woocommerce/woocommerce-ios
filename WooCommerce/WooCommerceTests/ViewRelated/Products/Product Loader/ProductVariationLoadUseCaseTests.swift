import XCTest
@testable import WooCommerce
import Yosemite
import Networking

final class ProductVariationLoadUseCaseTests: XCTestCase {
    typealias ResultData = ProductVariationLoadUseCase.ResultData
    private var stores: MockStoresManager!
    private let siteID: Int64 = 208

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting(authenticated: true))
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_loadProductVariation_successfully_returns_both_variation_and_product() throws {
        // Arrange
        let variation = MockProductVariation().productVariation()
        let product = MockProduct().product()
        let useCase = ProductVariationLoadUseCase(siteID: siteID, stores: stores)
        mockRetrieveProductVariation(result: .success(variation))
        mockRetrieveProduct(result: .success(product))

        // Action
        let result = try waitFor { promise in
            useCase.loadProductVariation(productID: 806, variationID: 725) { result in
                promise(result)
            }
        }

        // Assert
        XCTAssertEqual(stores.receivedActions.count, 2)
        XCTAssertNotNil(stores.receivedActions[0] as? ProductVariationAction)
        XCTAssertNotNil(stores.receivedActions[1] as? ProductAction)
        XCTAssertEqual(result, .success(ResultData(variation: variation, parentProduct: product)))
    }

    func test_loadProductVariation_with_variation_error_returns_the_error() throws {
        // Arrange
        let product = MockProduct().product()
        let useCase = ProductVariationLoadUseCase(siteID: siteID, stores: stores)
        mockRetrieveProductVariation(result: .failure(ProductVariationLoadError.unexpected))
        mockRetrieveProduct(result: .success(product))

        // Action
        let result = try waitFor { promise in
            useCase.loadProductVariation(productID: 806, variationID: 725) { result in
                promise(result)
            }
        }

        // Assert
        XCTAssertEqual(stores.receivedActions.count, 2)
        XCTAssertNotNil(stores.receivedActions[0] as? ProductVariationAction)
        XCTAssertNotNil(stores.receivedActions[1] as? ProductAction)
        XCTAssertEqual(result, .failure(.init(ProductVariationLoadError.unexpected)))
    }

    func test_loadProductVariation_with_product_error_returns_the_error() throws {
        // Arrange
        let variation = MockProductVariation().productVariation()
        let useCase = ProductVariationLoadUseCase(siteID: siteID, stores: stores)
        mockRetrieveProductVariation(result: .success(variation))
        mockRetrieveProduct(result: .failure(ProductLoadError.notFoundInStorage))

        // Action
        let result = try waitFor { promise in
            useCase.loadProductVariation(productID: 806, variationID: 725) { result in
                promise(result)
            }
        }

        // Assert
        XCTAssertEqual(stores.receivedActions.count, 2)
        XCTAssertNotNil(stores.receivedActions[0] as? ProductVariationAction)
        XCTAssertNotNil(stores.receivedActions[1] as? ProductAction)
        XCTAssertEqual(result, .failure(.init(ProductLoadError.notFoundInStorage)))
    }

    func test_loadProductVariation_with_variation_and_product_error_returns_the_variation_error() throws {
        // Arrange
        let useCase = ProductVariationLoadUseCase(siteID: siteID, stores: stores)
        mockRetrieveProductVariation(result: .failure(NetworkError.timeout))
        mockRetrieveProduct(result: .failure(ProductLoadError.notFoundInStorage))

        // Action
        let result = try waitFor { promise in
            useCase.loadProductVariation(productID: 806, variationID: 725) { result in
                promise(result)
            }
        }

        // Assert
        XCTAssertEqual(stores.receivedActions.count, 2)
        XCTAssertNotNil(stores.receivedActions[0] as? ProductVariationAction)
        XCTAssertNotNil(stores.receivedActions[1] as? ProductAction)
        XCTAssertEqual(result, .failure(.init(NetworkError.timeout)))
    }
}

private extension ProductVariationLoadUseCaseTests {
    func mockRetrieveProductVariation(result: Result<ProductVariation, Error>) {
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            if case let ProductVariationAction.retrieveProductVariation(_, _, _, onCompletion: onCompletion) = action {
                onCompletion(result)
            }
        }
    }

    func mockRetrieveProduct(result: Result<Product, Error>) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.retrieveProduct(_, _, onCompletion) = action {
                onCompletion(result)
            }
        }
    }
}
