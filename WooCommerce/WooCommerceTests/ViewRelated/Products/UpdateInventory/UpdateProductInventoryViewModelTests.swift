import XCTest
import Yosemite
import Fakes
@testable import WooCommerce

@MainActor
final class UpdateProductInventoryViewModelTests: XCTestCase {
    private var viewModel: UpdateProductInventoryViewModel!
    let siteID: Int64 = 1

    func test_quantity_when_we_pass_a_product_it_shows_right_quantity() {
        // Given
        let stockQuantity = Decimal(12)
        let product = Product.fake().copy(siteID: siteID, stockQuantity: stockQuantity)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.quantity, stockQuantity.formatted())
    }

    func test_quantity_when_we_pass_a_variation_it_shows_right_quantity() {
        // Given
        let stockQuantity = Decimal(12)
        let variation = ProductVariation.fake().copy(siteID: siteID, stockQuantity: stockQuantity)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.quantity, stockQuantity.formatted())
    }

    func test_sku_when_we_pass_a_product_it_shows_right_sku() {
        // Given
        let sku = "test-sku"
        let product = Product.fake().copy(siteID: siteID, sku: sku)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.sku, sku)
    }

    func test_sku_when_we_pass_a_variation_it_shows_right_sku() {
        // Given
        let sku = "test-sku"
        let variation = ProductVariation.fake().copy(siteID: siteID, sku: sku)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.sku, sku)
    }

    func test_imageURL_when_we_pass_a_product_it_shows_right_url() {
        // Given
        let url = "www.picture.com"
        let product = Product.fake().copy(siteID: siteID, images: [ProductImage.fake().copy(src: url)])
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.imageURL?.absoluteString, url)
    }

    func test_imageURL_when_we_pass_a_variation_it_shows_right_url() {
        // Given
        let url = "www.picture.com"
        let variation = ProductVariation.fake().copy(siteID: siteID, image: ProductImage.fake().copy(src: url))
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.imageURL?.absoluteString, url)
    }

    func test_name_when_we_pass_a_product_it_shows_right_name() {
        // Given
        let name = "test-name"
        let product = Product.fake().copy(siteID: siteID, name: name)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        waitUntil {
            viewModel.name == name
        }
    }

    func test_name_when_we_pass_a_variation_it_shows_the_parent_product_name() {
        // Given
        let parentProductID: Int64 = 12345
        let name = "test-name"
        let parentProduct = Product.fake().copy(siteID: siteID, productID: parentProductID, name: name)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: ProductAction.self) { [weak self ]action in
            guard let self = self else { return }
            switch action {
            case let .retrieveProduct(passingSiteID, productID, onCompletion):
                if passingSiteID == self.siteID,
                   productID == parentProductID {
                    onCompletion(.success(parentProduct))
                }
            default:
                break
            }
        }

        let product = ProductVariation.fake().copy(siteID: siteID, productID: parentProductID)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores)

        waitUntil {
            viewModel.name == name
        }
    }

    func test_onTapIncreaseStockQuantityOnce_with_a_product_then_increases_the_amount_and_sends_action() async throws {
        // Given
        let previousStockQuantity: Decimal = 5
        var passedStockQuantity: Decimal?
        let product = Product.fake().copy(siteID: siteID, stockQuantity: previousStockQuantity)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(passingProduct, onCompletion):
                passedStockQuantity = passingProduct.stockQuantity
                onCompletion(.success((product.copy(stockQuantity: previousStockQuantity + 1))))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores)

        // When
        viewModel.quantity = previousStockQuantity.formatted()
        await viewModel.onTapIncreaseStockQuantityOnce()

        // Then
        XCTAssertEqual(viewModel.quantity, passedStockQuantity?.formatted())
        XCTAssertEqual(passedStockQuantity, previousStockQuantity + 1)
        XCTAssertEqual(viewModel.updateQuantityButtonMode, .increaseOnce)
    }

    func test_onTapIncreaseStockQuantityOnce_with_a_variation_then_increases_the_amount_and_sends_action() async throws {
        // Given
        let previousStockQuantity: Decimal = 5
        var passedStockQuantity: Decimal?
        let stockQuantity = Decimal(12)
        let variation = ProductVariation.fake().copy(siteID: siteID, stockQuantity: stockQuantity)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .updateProductVariation(passingVariation, onCompletion):
                passedStockQuantity = passingVariation.stockQuantity
                onCompletion(.success((variation.copy(stockQuantity: previousStockQuantity + 1))))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID, stores: stores)

        // When
        viewModel.quantity = previousStockQuantity.formatted()
        await viewModel.onTapIncreaseStockQuantityOnce()

        // Then
        XCTAssertEqual(viewModel.quantity, passedStockQuantity?.formatted())
        XCTAssertEqual(passedStockQuantity, previousStockQuantity + 1)
        XCTAssertEqual(viewModel.updateQuantityButtonMode, .increaseOnce)
    }

    func test_onTapUpdateStockQuantity_with_a_product_then_sends_action() async throws {
        // Given
        let stockQuantity: Decimal = 23
        var passedStockQuantity: Decimal?
        let product = Product.fake().copy(siteID: siteID, stockQuantity: 12)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(passingProduct, onCompletion):
                passedStockQuantity = passingProduct.stockQuantity
                onCompletion(.success((product.copy(stockQuantity: stockQuantity))))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores)

        // When
        viewModel.quantity = stockQuantity.formatted()
        await viewModel.onTapUpdateStockQuantity()

        // Then
        XCTAssertEqual(passedStockQuantity, stockQuantity)
        XCTAssertEqual(viewModel.updateQuantityButtonMode, .increaseOnce)
    }

    func test_onTapUpdateStockQuantity_with_a_variation_then_sends_action() async throws {
        // Given
        let stockQuantity: Decimal = 23
        var passedStockQuantity: Decimal?
        let variation = ProductVariation.fake().copy(siteID: siteID, stockQuantity: stockQuantity)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .updateProductVariation(passingProduct, onCompletion):
                passedStockQuantity = passingProduct.stockQuantity
                onCompletion(.success((variation.copy(stockQuantity: stockQuantity))))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID, stores: stores)

        // When
        viewModel.quantity = stockQuantity.formatted()
        await viewModel.onTapUpdateStockQuantity()

        // Then
        XCTAssertEqual(passedStockQuantity, stockQuantity)
        XCTAssertEqual(viewModel.updateQuantityButtonMode, .increaseOnce)
    }

    func test_init_with_non_managed_stock_product_then_view_mode_is_stockManagementNeedsToBeEnabled() {
        // Given
        let product = Product.fake().copy(siteID: siteID, manageStock: false)

        // When
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.viewMode, .stockManagementNeedsToBeEnabled)
    }

    func test_init_with_non_managed_stock_variation_then_view_mode_is_stockManagementNeedsToBeEnabled() {
        // Given
        let variation = ProductVariation.fake().copy(siteID: siteID, manageStock: false)

        // When
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.viewMode, .stockManagementNeedsToBeEnabled)
    }

    func test_onTapManageStock_with_a_product_then_sends_action() async throws {
        // Given
        let product = Product.fake().copy(siteID: siteID, manageStock: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var passedManagedStockValue: Bool?
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(passingProduct, onCompletion):
                passedManagedStockValue = passingProduct.manageStock
                onCompletion(.success((product.copy(manageStock: true))))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores)

        // When
        try await viewModel.onTapManageStock()

        // Then
        XCTAssertTrue(passedManagedStockValue ?? false)
        XCTAssertEqual(viewModel.viewMode, .stockCanBeManaged)
    }

    func test_onTapManageStock_with_a_variation_then_sends_action() async throws {
        // Given
        let product = ProductVariation.fake().copy(siteID: siteID, manageStock: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var passedManagedStockValue: Bool?
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .updateProductVariation(productVariation, onCompletion):
                passedManagedStockValue = productVariation.manageStock
                onCompletion(.success((productVariation.copy(manageStock: true))))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores)

        // When
        try await viewModel.onTapManageStock()

        // Then
        XCTAssertTrue(passedManagedStockValue ?? false)
        XCTAssertEqual(viewModel.viewMode, .stockCanBeManaged)
    }
}
