import XCTest
import Yosemite
import Fakes
import TestKit
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

    func test_init_with_non_managed_stock_product_then_view_mode_is_stockManagementNeedsToBeEnabled() {
        // Given
        let product = Product.fake().copy(siteID: siteID, manageStock: false)

        // When
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, onUpdatedInventory: { _ in })

        // Then
        XCTAssertEqual(viewModel.viewMode, .stockManagementNeedsToBeEnabled)
    }

    func test_init_with_non_managed_stock_variation_then_view_mode_is_stockManagementNeedsToBeEnabled() {
        // Given
        let variation = ProductVariation.fake().copy(siteID: siteID, manageStock: false)

        // When
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID, onUpdatedInventory: { _ in })

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

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores, onUpdatedInventory: { _ in })

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

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores, onUpdatedInventory: { _ in })

        // When
        try await viewModel.onTapManageStock()

        // Then
        XCTAssertTrue(passedManagedStockValue ?? false)
        XCTAssertEqual(viewModel.viewMode, .stockCanBeManaged)
    }

    func test_when_onTapIncreaseStockQuantityOnce_then_product_quick_inventory_update_increment_quantity_tapped_is_tracked() async throws {
        // Given
        let product = Product.fake().copy(siteID: siteID, manageStock: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let expectedEvent = "product_quick_inventory_update_increment_quantity_tapped"

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(_, onCompletion):
                onCompletion(.success(product))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        analytics: analytics,
                                                        onUpdatedInventory: { _ in })
        // When
        try await viewModel.onTapIncreaseStockQuantityOnce()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent }))
    }

    func test_when_onTapUpdateStockQuantity_then_product_quick_inventory_update_manual_quantity_update_tapped_is_tracked() async throws {
        // Given
        let product = Product.fake().copy(siteID: siteID, manageStock: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let expectedEvent = "product_quick_inventory_update_manual_quantity_update_tapped"

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(_, onCompletion):
                onCompletion(.success(product))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        analytics: analytics,
                                                        onUpdatedInventory: { _ in })
        // When
        try await viewModel.onTapUpdateStockQuantity()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent }))
    }

    func test_when_onTapManageStock_succeeds_then_product_quick_inventory_enable_manage_stock_success_is_tracked() async throws {
        // Given
        let product = Product.fake().copy(siteID: siteID, manageStock: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        analytics: analytics,
                                                        onUpdatedInventory: { _ in })
        let expectedEvent = "product_quick_inventory_enable_manage_stock_success"

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(_, onCompletion):
                onCompletion(.success(product))
            default:
                break
            }
        }

        // When
        try await viewModel.onTapManageStock()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent }))
    }

    func test_when_onTapManageStock_fails_then_product_quick_inventory_enable_manage_stock_failure_is_tracked() async throws {
        // Given
        let product = Product.fake().copy(siteID: siteID, manageStock: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        analytics: analytics,
                                                        onUpdatedInventory: { _ in })
        let expectedEvent = "product_quick_inventory_enable_manage_stock_failure"

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(_, onCompletion):
                onCompletion(.failure(ProductUpdateError.notFoundInStorage))
            default:
                break
            }
        }

        /// When - Then
        await assertThrowsError({
            try await viewModel.onTapManageStock()
        }, errorAssert: { _ in
            analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent })
        })
    }

    func test_when_onViewProductDetailsButtonTapped_then_product_quick_inventory_view_product_details_tapped_is_tracked() {
        // Given
        let product = ProductVariation.fake().copy(siteID: siteID, manageStock: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        analytics: analytics,
                                                        onUpdatedInventory: { _ in })
        // When
        viewModel.onViewProductDetailsButtonTapped()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["product_quick_inventory_view_product_details_tapped"])
    }

    func test_when_onDismiss_tapped_then_product_quick_inventory_update_dismissed_is_tracked() {
        // Given
        let product = ProductVariation.fake().copy(siteID: siteID, manageStock: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product,
                                                        siteID: siteID,
                                                        stores: stores,
                                                        analytics: analytics,
                                                        onUpdatedInventory: { _ in })
        // When
        viewModel.onDismiss()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["product_quick_inventory_update_dismissed"])
    }

    func test_onTapManageStock_when_we_get_an_error_then_throws_error() async throws {
        // Given
        let product = Product.fake().copy(siteID: siteID, manageStock: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(_, onCompletion):
                onCompletion(.failure(ProductUpdateError.notFoundInStorage))
            default:
                break
            }
        }

        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores, onUpdatedInventory: { _ in })

        /// When - Then
        await assertThrowsError({ try await viewModel.onTapManageStock() }, errorAssert: { ($0 as? UpdateInventoryError) ==  UpdateInventoryError.generic })
    }
}
