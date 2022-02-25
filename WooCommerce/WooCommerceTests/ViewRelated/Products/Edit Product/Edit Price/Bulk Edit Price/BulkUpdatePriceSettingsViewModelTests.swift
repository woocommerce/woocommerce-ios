import XCTest
@testable import WooCommerce
@testable import Yosemite

/// Tests for `BulkUpdatePriceSettingsViewModel`
///
final class BulkUpdatePriceSettingsViewModelTests: XCTestCase {

    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    func test_initial_viewModel_state() {
        // Given
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0, productID: 0, productVariations: [], edittingPriceType: .regular, priceUpdateDidFinish: { })

        // Then
        XCTAssertEqual(viewModel.buttonState, .disabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertNil(viewModel.priceValidationError)
    }

    func test_state_when_price_is_changed_from_empty_to_a_value() {
        // Given
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0, productID: 0, productVariations: [], edittingPriceType: .regular, priceUpdateDidFinish: { })

        viewModel.handlePriceChange("42")

        // Then
        XCTAssertEqual(viewModel.buttonState, .enabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertNil(viewModel.priceValidationError)
    }

    func test_state_when_price_is_changed_from_a_value_to_empty() {
        // Given
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0, productID: 0, productVariations: [], edittingPriceType: .regular, priceUpdateDidFinish: { })

        viewModel.handlePriceChange("")

        // Then
        XCTAssertEqual(viewModel.buttonState, .disabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertNil(viewModel.priceValidationError)
    }

    func test_state_when_no_regular_price_is_selected_and_save_button_tapped_given_variations_have_sale_price() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), salePrice: "42")]
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .regular,
                                                         priceUpdateDidFinish: { })

        // When
        viewModel.saveButtonTapped()

        // Then
        XCTAssertEqual(viewModel.buttonState, .disabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertEqual(viewModel.priceValidationError, .salePriceWithoutRegularPrice)
    }

    func test_state_when_no_regular_price_is_selected_and_save_button_tapped_given_with_multiple_variations_having_sale_price() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "43", salePrice: "42"),
                          MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), salePrice: "42")]
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .regular,
                                                         priceUpdateDidFinish: { })

        // When
        viewModel.saveButtonTapped()

        // Then
        XCTAssertEqual(viewModel.buttonState, .disabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertEqual(viewModel.priceValidationError, .salePriceWithoutRegularPrice)
    }

    func test_state_when_no_sale_price_is_selected_and_save_button_tapped_given_variations_with_no_prices() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date())]
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .sale,
                                                         priceUpdateDidFinish: { })

        // When
        viewModel.saveButtonTapped()

        // Then
        XCTAssertEqual(viewModel.buttonState, .disabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertEqual(viewModel.priceValidationError, .newSaleWithEmptySalePrice)
    }

    func test_state_when_no_sale_price_is_selected_and_save_button_tapped_givenwith_multiple_variations_with_no_prices() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date()),
                          MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date())]
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .sale,
                                                         priceUpdateDidFinish: { })

        // When
        viewModel.saveButtonTapped()

        // Then
        XCTAssertEqual(viewModel.buttonState, .disabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertEqual(viewModel.priceValidationError, .newSaleWithEmptySalePrice)
    }

    func test_state_when_selected_sale_price_is_greater_than_regular_price() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "10")]
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .sale,
                                                         priceUpdateDidFinish: { })

        // When
        viewModel.handlePriceChange("42")
        viewModel.saveButtonTapped()

        // Then
        XCTAssertEqual(viewModel.buttonState, .enabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertEqual(viewModel.priceValidationError, .salePriceHigherThanRegularPrice)
    }

    func test_state_when_selected_sale_price_is_greater_than_regular_price_with_multiple_variations() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "50"),
                          MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "10")]
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .sale,
                                                         priceUpdateDidFinish: { })

        // When
        viewModel.handlePriceChange("42")
        viewModel.saveButtonTapped()

        // Then
        XCTAssertEqual(viewModel.buttonState, .enabled)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertEqual(viewModel.priceValidationError, .salePriceHigherThanRegularPrice)
    }

    func test_state_when_selected_valid_price_is_valid_when_action_is_dispatched() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "50")]
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { _ in
            // do nothing to stay in "syncing" state
        }
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .sale,
                                                         priceUpdateDidFinish: { },
                                                         storesManager: storesManager)

        // When
        viewModel.handlePriceChange("9")
        viewModel.saveButtonTapped()

        // Then
        XCTAssertEqual(viewModel.buttonState, .loading)
        XCTAssertFalse(viewModel.lastUpdateDidFail)
        XCTAssertNil(viewModel.priceValidationError)
    }

    func test_state_when_selected_valid_price_is_valid_when_action_fails() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "50")]
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .updateProductVariations(_, _, _, onCompletion):
                onCompletion(.failure(.unexpected))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .sale,
                                                         priceUpdateDidFinish: { },
                                                         storesManager: storesManager)

        // When
        viewModel.handlePriceChange("9")
        viewModel.saveButtonTapped()

        // Then
        XCTAssertEqual(viewModel.buttonState, .enabled)
        XCTAssertTrue(viewModel.lastUpdateDidFail)
        XCTAssertNil(viewModel.priceValidationError)
    }

    func test_callback_is_called_when_update_action_is_successful() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "50")]
        var isCallbackCalled = false
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action  in
            switch action {
            case let .updateProductVariations(_, _, _, onCompletion):
                onCompletion(.success([]))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         productVariations: variations,
                                                         edittingPriceType: .sale,
                                                         priceUpdateDidFinish: {
                                                            isCallbackCalled = true
                                                         },
                                                         storesManager: storesManager)

        // When
        viewModel.handlePriceChange("9")
        viewModel.saveButtonTapped()


        // Then
        waitUntil {
            isCallbackCalled
        }
        XCTAssertTrue(isCallbackCalled)
    }
}
