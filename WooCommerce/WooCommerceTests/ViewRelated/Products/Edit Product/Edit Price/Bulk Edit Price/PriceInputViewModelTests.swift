import XCTest
@testable import WooCommerce
@testable import Yosemite

/// Tests for `PriceInputViewModel`
///
final class PriceInputViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 123
    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    func test_initial_viewModel_state() throws {
        // Given
        let listViewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, regularPrice: "100")
        listViewModel.selectProduct(sampleProduct1)

        let viewModel = PriceInputViewModel(productListViewModel: listViewModel)

        // Then
        XCTAssertEqual(viewModel.applyButtonEnabled, false)
        XCTAssertNil(viewModel.inputValidationError)
        XCTAssertTrue(viewModel.footerText.isNotEmpty)
    }

    func test_state_when_price_is_changed_from_empty_to_a_value() {
        // Given
        let listViewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, regularPrice: "100")
        listViewModel.selectProduct(sampleProduct1)

        let viewModel = PriceInputViewModel(productListViewModel: listViewModel)

        // When
        viewModel.handlePriceChange("42")

        // Then
        XCTAssertEqual(viewModel.applyButtonEnabled, true)
        XCTAssertNil(viewModel.inputValidationError)
    }

    func test_state_when_price_is_changed_from_a_value_to_empty() {
        // Given
        let listViewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, regularPrice: "100")
        listViewModel.selectProduct(sampleProduct1)

        let viewModel = PriceInputViewModel(productListViewModel: listViewModel)

        // When
        viewModel.handlePriceChange("")

        // Then
        XCTAssertEqual(viewModel.applyButtonEnabled, false)
        XCTAssertNil(viewModel.inputValidationError)
    }

    func test_state_when_selected_regular_price_is_less_than_sale_price() {
        // Given
        let listViewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "100", salePrice: "42")
        listViewModel.selectProduct(sampleProduct1)

        let viewModel = PriceInputViewModel(productListViewModel: listViewModel)

        // When
        viewModel.handlePriceChange("24")
        viewModel.applyButtonTapped()

        // Then
        XCTAssertEqual(viewModel.applyButtonEnabled, true)
        XCTAssertEqual(viewModel.inputValidationError, .salePriceHigherThanRegularPrice)
    }

    func test_state_when_selected_valid_price_is_valid_and_action_is_dispatched() {
        // Given
        var callbackValue: String?
        let listViewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, regularPrice: "100")
        listViewModel.selectProduct(sampleProduct1)

        let viewModel = PriceInputViewModel(productListViewModel: listViewModel)
        viewModel.applyClosure = { result in
            callbackValue = result
        }

        // When
        viewModel.handlePriceChange("42")
        viewModel.applyButtonTapped()

        // Then
        XCTAssertEqual(viewModel.applyButtonEnabled, true)
        XCTAssertNil(viewModel.inputValidationError)
        XCTAssertEqual(callbackValue, "42")
    }
}
