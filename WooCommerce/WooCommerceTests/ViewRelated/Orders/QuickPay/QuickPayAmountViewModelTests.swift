import Foundation
import XCTest

@testable import WooCommerce
@testable import Yosemite

final class QuickPayAmountViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123

    func test_view_model_prepends_currency_symbol() {
        // Given
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.amount = "12"

        // Then
        XCTAssertEqual(viewModel.amount, "$12")
    }

    func test_view_model_removes_non_digit_characters() {
        // Given
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.amount = "hi:11.30-"

        // Then
        XCTAssertEqual(viewModel.amount, "$11.30")
    }

    func test_view_model_trims_more_than_two_decimal_numbers() {
        // Given
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.amount = "$67.321432432"

        // Then
        XCTAssertEqual(viewModel.amount, "$67.32")
    }

    func test_view_model_removes_duplicated_decimal_separators() {
        // Given
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.amount = "$6.7.3"

        // Then
        XCTAssertEqual(viewModel.amount, "$6.7")
    }

    func test_view_model_removes_consecutive_decimal_separators() {
        // Given
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.amount = "$6..."

        // Then
        XCTAssertEqual(viewModel.amount, "$6.")
    }

    func test_view_model_disables_next_button_when_there_is_no_amount() {
        // Given
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.amount = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_next_button_when_amount_only_has_currency_symbol() {
        // Given
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.amount = "$"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_enables_next_button_when_amount_has_more_than_one_character() {
        // Given
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.amount = "$2"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_enables_loading_state_while_performing_network_operations() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = QuickPayAmountViewModel(siteID: sampleSiteID, stores: testingStore)
        viewModel.amount = "$12.30"
        XCTAssertFalse(viewModel.loading)

        // When
        let isLoading: Bool = waitFor { promise in
            testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createQuickPayOrder:
                    promise(viewModel.loading)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createQuickPayOrder { _ in }
        }

        // Then
        XCTAssertTrue(isLoading)
    }
}
