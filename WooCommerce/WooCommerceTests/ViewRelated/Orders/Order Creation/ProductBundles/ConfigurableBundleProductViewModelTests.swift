import XCTest
import Yosemite
@testable import WooCommerce

final class ConfigurableBundleProductViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        stores = nil
        super.tearDown()
    }

    // MARK: - Validation

    func test_validation_is_failure_when_bundle_item_is_invalid() throws {
        // Given
        // The bundle size has to be 5.
        let product = Product.fake().copy(productID: 1, bundleMinSize: nil, bundleMaxSize: 5, bundledItems: [
            // One optional item
            .fake().copy(bundledItemID: 1, productID: 2, isOptional: false)
        ])
        let productsFromRetrieval = [1, 2].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: self.stores,
                                                           onConfigure: { _ in })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        XCTAssertTrue(viewModel.isConfigureEnabled)

        // When
        // Simulates a validation error when quantity exceeds the max size (`bundleMaxSize`).
        let item = try XCTUnwrap(viewModel.bundleItemViewModels[0])
        item.quantity = 6

        // Then
        XCTAssertFalse(viewModel.isConfigureEnabled)

        // When the item becomes valid
        item.quantity = 5

        // Then
        XCTAssertTrue(viewModel.isConfigureEnabled)
    }

    func test_validation_is_success_when_bundle_size_matches() throws {
        // Given
        // The bundle size has to be 5.
        let product = Product.fake().copy(productID: 1, bundleMinSize: 5, bundleMaxSize: 5, bundledItems: [
            // One optional item
            .fake().copy(bundledItemID: 1, productID: 2, isOptional: true),
            .fake().copy(bundledItemID: 2, productID: 3, isOptional: false)
        ])
        let productsFromRetrieval = [1, 2, 3].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: self.stores,
                                                           onConfigure: { _ in })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        XCTAssertFalse(viewModel.isConfigureEnabled)
        XCTAssertTrue(viewModel.validationState.isFailure)

        // Optional non-selected bundle item quantity is not counted for the bundle size.
        let optionalItem = try XCTUnwrap(viewModel.bundleItemViewModels[0])
        optionalItem.quantity = 3
        optionalItem.isOptionalAndSelected = true

        let nonOptionalItem = try XCTUnwrap(viewModel.bundleItemViewModels[1])
        nonOptionalItem.quantity = 2

        // Then
        XCTAssertTrue(viewModel.isConfigureEnabled)
        XCTAssertTrue(viewModel.validationState.isSuccess)
    }

    func test_validation_is_success_when_default_bundle_size_matches() throws {
        // Given
        // The bundle size has to be 5.
        let product = Product.fake().copy(productID: 1, bundleMinSize: 5, bundleMaxSize: 5, bundledItems: [
            // Both items are required and the total default quantity matches the min bundle size.
            .fake().copy(bundledItemID: 1, productID: 2, defaultQuantity: 2, isOptional: false),
            .fake().copy(bundledItemID: 2, productID: 3, defaultQuantity: 3, isOptional: false)
        ])
        let productsFromRetrieval = [1, 2, 3].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: self.stores,
                                                           onConfigure: { _ in })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        XCTAssertTrue(viewModel.isConfigureEnabled)
        XCTAssertTrue(viewModel.validationState.isSuccess)
    }

    func test_validation_is_failure_when_bundle_size_exceeds_max() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundleMaxSize: 5, bundledItems: [
            // One optional item
            .fake().copy(productID: 2, isOptional: true),
            .fake().copy(productID: 3, isOptional: false)
        ])
        let productsFromRetrieval = [1, 2, 3].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: self.stores,
                                                           onConfigure: { _ in })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        // Optional non-selected bundle item quantity is not counted for the bundle size.
        let optionalItem = try XCTUnwrap(viewModel.bundleItemViewModels[0])
        optionalItem.quantity = 6
        optionalItem.isOptionalAndSelected = false

        XCTAssertTrue(viewModel.isConfigureEnabled)

        let nonOptionalItem = try XCTUnwrap(viewModel.bundleItemViewModels[1])
        nonOptionalItem.quantity = 6

        // Then
        XCTAssertFalse(viewModel.isConfigureEnabled)
        XCTAssertTrue(viewModel.validationState.isFailure)
    }

    func test_validation_is_failure_when_bundle_size_smaller_than_min() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundleMinSize: 5, bundledItems: [
            .fake().copy(productID: 2)
        ])
        let productsFromRetrieval = [1, 2].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: self.stores,
                                                           onConfigure: { _ in })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        let item = try XCTUnwrap(viewModel.bundleItemViewModels[0])
        item.quantity = 4

        // Then
        XCTAssertFalse(viewModel.isConfigureEnabled)
        XCTAssertTrue(viewModel.validationState.isFailure)
    }

    // MARK: - `loadProductsErrorMessage`

    func test_loadProductsErrorMessage_is_set_when_retrieveProducts_fails() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundledItems: [
            .fake().copy(productID: 2)
        ])
        mockProductsRetrieval(result: .failure(NSError(domain: "", code: 0, userInfo: nil)))

        // When
        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: stores,
                                                           onConfigure: { _ in })

        // Then
        waitUntil {
            viewModel.loadProductsErrorMessage != nil
        }
    }

    func test_errorMessage_is_reset_when_retrieveProducts_fails_then_succeeds_after_retry() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundledItems: [
            .fake().copy(productID: 2)
        ])
        mockProductsRetrieval(result: .failure(NSError(domain: "", code: 0, userInfo: nil)))

        // When
        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: stores,
                                                           onConfigure: { _ in })
        waitUntil {
            viewModel.loadProductsErrorMessage != nil
        }
        let productsFromRetrieval = [1, 2].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))
        viewModel.retry()

        // Then
        waitUntil {
            viewModel.loadProductsErrorMessage == nil
        }
    }

    func test_configure_invokes_onConfigure_if_configuration_is_changed() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundledItems: [
            .fake().copy(productID: 2)
        ])
        let productsFromRetrieval = [1, 2].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        var configurationsFromOnConfigure: [BundledProductConfiguration] = []
        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: self.stores,
                                                           onConfigure: { configurations in
            configurationsFromOnConfigure = configurations
        })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        // When altering the bundle item
        let bundleItemViewModel = try XCTUnwrap(viewModel.bundleItemViewModels.first)
        bundleItemViewModel.quantity = 8

        viewModel.configure()

        waitUntil {
            configurationsFromOnConfigure.isNotEmpty
        }

        // Then
        let configurationFromOnConfigure = try XCTUnwrap(configurationsFromOnConfigure.first)
        XCTAssertEqual(configurationFromOnConfigure.quantity, 8)
    }

    func test_configure_does_not_invoke_onConfigure_if_configuration_is_the_same_when_bundle_is_not_new() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundledItems: [
            .fake().copy(productID: 2)
        ])
        let productsFromRetrieval = [1, 2].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           // The bundle is not new when there are non-empty child items.
                                                           childItems: [.fake()],
                                                           stores: stores,
                                                           onConfigure: { configurations in
            // Then
            XCTFail("The configure closure should not be invoked")
        })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        // When
        viewModel.configure()
    }

    func test_configure_invokes_onConfigure_if_configuration_is_the_same_when_bundle_is_new() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundledItems: [
            .fake().copy(productID: 2, minQuantity: 2, maxQuantity: 8, defaultQuantity: 6)
        ])
        let productsFromRetrieval = [1, 2].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        var configurationsFromOnConfigure: [BundledProductConfiguration] = []
        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           // The bundle is new when there are no child items.
                                                           childItems: [],
                                                           stores: stores,
                                                           onConfigure: { configurations in
            // Then
            configurationsFromOnConfigure = configurations
        })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        // When
        viewModel.configure()

        // Then the quantity is the default quantity
        let configurationFromOnConfigure = try XCTUnwrap(configurationsFromOnConfigure.first)
        XCTAssertEqual(configurationFromOnConfigure.quantity, 6)
    }

    func test_bundleItemViewModels_have_correct_quantity_when_parent_order_item_quantity_is_more_than_one() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundledItems: [
            .fake().copy(productID: 2)
        ])
        let productsFromRetrieval = [1, 2].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        // When
        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           orderItem: .fake().copy(productID: 1, quantity: 3),
                                                           childItems: [
                                                            // The child item's quantity is multiplied by the parent item quantity.
                                                            .fake().copy(productID: 2, quantity: 9)
                                                           ],
                                                           stores: self.stores,
                                                           onConfigure: { _ in })

        // The products are loaded async before the bundle item view models are set.
        waitUntil {
            viewModel.bundleItemViewModels.isNotEmpty
        }

        // Then
        let bundleItemViewModel = try XCTUnwrap(viewModel.bundleItemViewModels.first)
        XCTAssertEqual(bundleItemViewModel.quantity, 3)
    }

    // MARK: - Analytics

    func test_configure_tracks_orderFormBundleProductConfigurationSaveTapped_event() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundledItems: [
            .fake().copy(productID: 2)
        ])

        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
                                                           stores: stores,
                                                           analytics: analytics,
                                                           onConfigure: { _ in })

        // When
        viewModel.configure()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["order_form_bundle_product_configuration_save_tapped"])
    }
}

private extension ConfigurableBundleProductViewModelTests {
    func mockProductsRetrieval(result: Result<(products: [Product], hasNextPage: Bool), Error>) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
                case let .retrieveProducts(_, _, _, _, onCompletion):
                    onCompletion(result)
                default:
                    XCTFail("Unexpected action: \(action)")
            }
        }
    }
}
