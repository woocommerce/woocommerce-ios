import XCTest
import Yosemite
import Combine
import WooFoundation
@testable import Storage

@testable import WooCommerce

/// Tests for `BulkUpdateViewModel`.
///
final class BulkUpdateViewModelTests: XCTestCase {

    private var storesManager: MockStoresManager!
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        storageManager = nil
        storesManager = nil
        super.tearDown()
    }

    func test_all_products_are_synchronized_on_the_viewload_event() throws {
        // Given
        let expectedSiteID: Int64 = 42
        let expectedProductID: Int64 = 19
        let expectedPageSize = 100
        let expectedPageNumber = 1
        let viewModel = BulkUpdateViewModel(siteID: expectedSiteID,
                                            productID: expectedProductID,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // When
        viewModel.syncVariations()

        // Then
        let action = try XCTUnwrap(storesManager.receivedActions.first as? ProductVariationAction)

        guard case let .synchronizeProductVariations(siteID: siteID, productID: productID, pageNumber: pageNumber, pageSize: pageSize, _, _, _) = action else {
            XCTFail("Expected \(action) to be \(ProductVariationAction.self).synchronizeProductVariations.")
            return
        }

        XCTAssertEqual(siteID, expectedSiteID)
        XCTAssertEqual(productID, expectedProductID)
        XCTAssertEqual(pageNumber, expectedPageNumber)
        XCTAssertEqual(pageSize, expectedPageSize)
    }

    func test_initial_sync_state() throws {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0,
                                            productID: 0,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // Then
        XCTAssertEqual(viewModel.syncState, .notStarted)
    }

    func test_sync_state_updates_to_loading_when_product_variations_syncing_starts() {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0,
                                            productID: 0,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { _ in
            // do nothing to stay in "syncing" state
        }

        // When
        viewModel.syncVariations()

        // Then
        XCTAssertEqual(viewModel.syncState, .syncing)
    }

    func test_sync_state_updates_to_syncerror_when_product_variations_syncing_fails() {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0,
                                            productID: 0,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, _, _, onCompletion):
                onCompletion(.failure(NSError.init(domain: "sample error", code: 0, userInfo: nil)))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.syncVariations()

        // Then
        XCTAssertEqual(viewModel.syncState, .error)
    }

    func test_sync_state_updates_to_syncResults_when_product_variations_syncing_is_successful() {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0,
                                            productID: 0,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.syncVariations()

        // Then
        XCTAssertEqual(viewModel.syncState, .synced([]))
    }

    func test_number_of_sections_and_title_when_in_synch_state() throws {
        //Given
        let product = Product.fake().copy(siteID: 1, productID: 1, productTypeKey: "variable", variations: [1, 2])
        let variations = [MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 1, regularPrice: "1")]
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[0], on: product)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action  in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewModel = BulkUpdateViewModel(siteID: 1,
                                            productID: 1,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // When
        viewModel.syncVariations()

        // Then
        waitUntil {
            viewModel.syncState.sections()?.isNotEmpty ?? false
        }

        XCTAssertEqual(viewModel.syncState.sections()?.count, 1)
        let sectionTitle = try XCTUnwrap(viewModel.syncState.sections()?.first?.title)
        XCTAssertTrue(sectionTitle.isNotEmpty)
    }

    func test_sale_price_description_when_all_products_have_same_price() {
        //Given
        let product = Product.fake().copy(siteID: 1, productID: 1, productTypeKey: "variable", variations: [1, 2])
        let variations = [MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 1, regularPrice: "1"),
                          MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 2, regularPrice: "1")]
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[0], on: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[1], on: product)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action  in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewModel = BulkUpdateViewModel(siteID: 1,
                                            productID: 1,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager,
                                            currencySettings: CurrencySettings())

        // When
        viewModel.syncVariations()

        // Then
        waitUntil {
            viewModel.syncState.sections()?.isNotEmpty ?? false
        }

        let regularPriceViewModel = viewModel.viewModelForDisplayingRegularPrice()
        XCTAssertFalse(regularPriceViewModel.text.isEmpty)
        XCTAssertEqual(regularPriceViewModel.detailText, "$1.00")
        XCTAssertEqual(regularPriceViewModel.style, .primary)
    }

    func test_sale_price_description_when_some_products_have_different_price() {
        //Given
        let product = Product.fake().copy(siteID: 1, productID: 1, productTypeKey: "variable", variations: [1, 2])
        let variations = [MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 1, regularPrice: "1"),
                          MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 2, regularPrice: "2")]
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[0], on: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[1], on: product)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action  in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewModel = BulkUpdateViewModel(siteID: 1,
                                            productID: 1,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // When
        viewModel.syncVariations()

        // Then
        waitUntil {
            viewModel.syncState.sections()?.isNotEmpty ?? false
        }

        let regularPriceViewModel = viewModel.viewModelForDisplayingRegularPrice()
        XCTAssertFalse(regularPriceViewModel.text.isEmpty)
        XCTAssertFalse(regularPriceViewModel.detailText.isEmpty)
        XCTAssertEqual(regularPriceViewModel.style, .primary)
    }

    func test_sale_price_description_when_all_products_have_no_price() {
        //Given
        let product = Product.fake().copy(siteID: 1, productID: 1, productTypeKey: "variable", variations: [1, 2])
        let variations = [MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 1),
                          MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 2)]
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[0], on: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[1], on: product)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action  in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewModel = BulkUpdateViewModel(siteID: 1,
                                            productID: 1,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // When
        viewModel.syncVariations()

        // Then
        waitUntil {
            viewModel.syncState.sections()?.isNotEmpty ?? false
        }

        let regularPriceViewModel = viewModel.viewModelForDisplayingRegularPrice()
        XCTAssertFalse(regularPriceViewModel.text.isEmpty)
        XCTAssertFalse(regularPriceViewModel.detailText.isEmpty)
        XCTAssertEqual(regularPriceViewModel.style, .secondary)
    }

    func test_sale_price_description_when_some_products_have_no_price() {
        //Given
        let product = Product.fake().copy(siteID: 1, productID: 1, productTypeKey: "variable", variations: [1, 2])
        let variations = [MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 1, regularPrice: "1"),
                          MockProductVariation().productVariation().copy(siteID: 1, productID: 1, productVariationID: 2)]
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[0], on: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variations[1], on: product)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action  in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewModel = BulkUpdateViewModel(siteID: 1,
                                            productID: 1,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // When
        viewModel.syncVariations()

        // Then
        waitUntil {
            viewModel.syncState.sections()?.isNotEmpty ?? false
        }

        let regularPriceViewModel = viewModel.viewModelForDisplayingRegularPrice()
        XCTAssertFalse(regularPriceViewModel.text.isEmpty)
        XCTAssertFalse(regularPriceViewModel.detailText.isEmpty)
        XCTAssertEqual(regularPriceViewModel.style, .primary)
    }

    func test_tapped_cancel_button_invokes_closure() {
        // Given
        var onCancelButtonTappedInvoked = false
        let viewModel = BulkUpdateViewModel(siteID: 0,
                                            productID: 0,
                                            variationCount: 10,
                                            onCancelButtonTapped: {
                                                onCancelButtonTappedInvoked = true
                                            },
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // When
        viewModel.handleTapCancel()

        // Then
        XCTAssertTrue(onCancelButtonTappedInvoked)
    }

    func test_less_than_100_variations_does_not_shows_warning() throws {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0,
                                            productID: 0,
                                            variationCount: 10,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // Then
        XCTAssertFalse(viewModel.shouldShowVariationLimitWarning)
    }

    func test_more_than_100_variations_shows_warning() throws {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0,
                                            productID: 0,
                                            variationCount: 101,
                                            onCancelButtonTapped: {},
                                            storageManager: storageManager,
                                            storesManager: storesManager)

        // Then
        XCTAssertTrue(viewModel.shouldShowVariationLimitWarning)
    }
}

private extension BulkUpdateViewModel.SyncState {
    /// Convenient method to access the sections value
    ///
    func sections() -> [BulkUpdateViewController.Section]? {
        switch self {
        case let .synced(sections):
            return sections
        default:
            return nil
        }
    }
}
