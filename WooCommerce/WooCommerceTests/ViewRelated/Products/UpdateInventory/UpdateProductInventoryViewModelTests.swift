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
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        onUpdatedInventory: { _ in })

        // Then
        XCTAssertEqual(viewModel.quantity, stockQuantity.formatted())
    }

    func test_quantity_when_we_pass_a_variation_it_shows_right_quantity() {
        // Given
        let stockQuantity = Decimal(12)
        let variation = ProductVariation.fake().copy(siteID: siteID, stockQuantity: stockQuantity)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation,
                                                        siteID: siteID,
                                                        onUpdatedInventory: { _ in })

        // Then
        XCTAssertEqual(viewModel.quantity, stockQuantity.formatted())
    }

    func test_sku_when_we_pass_a_product_it_shows_right_sku() {
        // Given
        let sku = "test-sku"
        let product = Product.fake().copy(siteID: siteID, sku: sku)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        onUpdatedInventory: { _ in })

        // Then
        XCTAssertEqual(viewModel.sku, sku)
    }

    func test_sku_when_we_pass_a_variation_it_shows_right_sku() {
        // Given
        let sku = "test-sku"
        let variation = ProductVariation.fake().copy(siteID: siteID, sku: sku)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation,
                                                        siteID: siteID,
                                                        onUpdatedInventory: { _ in })

        // Then
        XCTAssertEqual(viewModel.sku, sku)
    }

    func test_imageURL_when_we_pass_a_product_it_shows_right_url() {
        // Given
        let url = "www.picture.com"
        let product = Product.fake().copy(siteID: siteID, images: [ProductImage.fake().copy(src: url)])
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        onUpdatedInventory: { _ in })

        // Then
        XCTAssertEqual(viewModel.imageURL?.absoluteString, url)
    }

    func test_imageURL_when_we_pass_a_variation_it_shows_right_url() {
        // Given
        let url = "www.picture.com"
        let variation = ProductVariation.fake().copy(siteID: siteID, image: ProductImage.fake().copy(src: url))
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation,
                                                        siteID: siteID,
                                                        onUpdatedInventory: { _ in })

        // Then
        XCTAssertEqual(viewModel.imageURL?.absoluteString, url)
    }

    func test_notice_when_displayErrorNotice_in_invoked_then_displays_correct_error_notice() {
        // Given
        let product = Product.fake().copy(name: "Some Product")
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        onUpdatedInventory: { _ in })

        XCTAssertNil(viewModel.notice, "Precondition: Notice should be nil on init")

        // When
        viewModel.displayErrorNotice(product.name)

        // Then
        XCTAssertNotNil(viewModel.notice)
        XCTAssertEqual(viewModel.notice?.title, "Update Inventory Error")
        XCTAssertEqual(viewModel.notice?.message, "There was an error updating Some Product. Please try again.")
        XCTAssertEqual(viewModel.notice?.feedbackType, .error)
    }

    func test_name_when_we_pass_a_product_it_shows_right_name() {
        // Given
        let name = "test-name"
        let product = Product.fake().copy(siteID: siteID, name: name)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        onUpdatedInventory: { _ in })

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

        let variation = ProductVariation.fake().copy(siteID: siteID, productID: parentProductID)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        onUpdatedInventory: { _ in })

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

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        onUpdatedInventory: { _ in })

        // When
        viewModel.quantity = previousStockQuantity.formatted()
        try await viewModel.onTapIncreaseStockQuantityOnce()

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

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        onUpdatedInventory: { _ in })

        // When
        viewModel.quantity = previousStockQuantity.formatted()
        try await viewModel.onTapIncreaseStockQuantityOnce()

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

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        onUpdatedInventory: { _ in })

        // When
        viewModel.quantity = stockQuantity.formatted()
        try await viewModel.onTapUpdateStockQuantity()

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

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        onUpdatedInventory: { _ in })

        // When
        viewModel.quantity = stockQuantity.formatted()
        try await viewModel.onTapUpdateStockQuantity()

        // Then
        XCTAssertEqual(passedStockQuantity, stockQuantity)
        XCTAssertEqual(viewModel.updateQuantityButtonMode, .increaseOnce)
    }
}
