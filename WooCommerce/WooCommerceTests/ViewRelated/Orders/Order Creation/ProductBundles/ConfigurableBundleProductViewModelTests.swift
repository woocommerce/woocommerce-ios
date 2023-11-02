import XCTest
import Yosemite
@testable import WooCommerce

final class ConfigurableBundleProductViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
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

    func test_configure_does_not_invoke_onConfigure_if_configuration_is_the_same() throws {
        // Given
        let product = Product.fake().copy(productID: 1, bundledItems: [
            .fake().copy(productID: 2)
        ])
        let productsFromRetrieval = [1, 2].map { Product.fake().copy(productID: $0) }
        mockProductsRetrieval(result: .success((products: productsFromRetrieval, hasNextPage: false)))

        let viewModel = ConfigurableBundleProductViewModel(product: product,
                                                           childItems: [],
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
