import XCTest
import Yosemite
@testable import WooCommerce
import WooFoundation

final class SubscriptionExpiryViewModelTests: XCTestCase {
    func test_selectedLength_has_correct_value() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "0")
        let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { _, _ in }

        // Then
        XCTAssertEqual(viewModel.selectedLength.title, SubscriptionExpiryViewModel.Localization.neverExpire)
        XCTAssertEqual(viewModel.selectedLength.value, 0)
        XCTAssertEqual(viewModel.selectedLength.stringValue, "0")
    }

    func test_selectedLength_and_lengthOptions_are_correct_if_periodInterval_is_0() {
        // Given
        let subscription = ProductSubscription.fake().copy(periodInterval: "0")
        let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { _, _ in }

        // Then
        XCTAssertEqual(viewModel.selectedLength.value, 0)
        XCTAssertEqual(viewModel.lengthOptions.count, 1)
    }

    func test_lengthOptions_has_values_based_on_period_and_periodInterval_for_day() throws {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1",
                                                           period: .day,
                                                           periodInterval: "1")
        let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { _, _ in }

        // Then
        let lengthOption = try XCTUnwrap(viewModel.lengthOptions.first)
        XCTAssertEqual(lengthOption.title, SubscriptionExpiryViewModel.Localization.neverExpire)
        XCTAssertEqual(viewModel.lengthOptions.count, 91)
    }

    func test_lengthOptions_has_values_based_on_period_and_periodInterval_for_week() throws {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1",
                                                           period: .month,
                                                           periodInterval: "4")
        let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { _, _ in }

        // Then
        let lengthOption = try XCTUnwrap(viewModel.lengthOptions.first)
        XCTAssertEqual(lengthOption.title, SubscriptionExpiryViewModel.Localization.neverExpire)
        XCTAssertEqual(viewModel.lengthOptions.count, 7)
    }

    func test_lengthOptions_has_values_based_on_period_and_periodInterval_for_month() throws {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1",
                                                           period: .month,
                                                           periodInterval: "2")
        let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { _, _ in }

        // Then
        let lengthOption = try XCTUnwrap(viewModel.lengthOptions.first)
        XCTAssertEqual(lengthOption.title, SubscriptionExpiryViewModel.Localization.neverExpire)
        XCTAssertEqual(viewModel.lengthOptions.count, 13)
    }

    func test_lengthOptions_has_values_based_on_period_and_periodInterval_for_year() throws {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1",
                                                           period: .year,
                                                           periodInterval: "1")
        let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { _, _ in }

        // Then
        let lengthOption = try XCTUnwrap(viewModel.lengthOptions.first)
        XCTAssertEqual(lengthOption.title, SubscriptionExpiryViewModel.Localization.neverExpire)
        XCTAssertEqual(viewModel.lengthOptions.count, 6)
    }

    // MARK: Done button

    func test_done_button_is_enabled_only_when_selection_changes() throws {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1",
                                                           period: .month,
                                                           periodInterval: "1")
        let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { _, _ in }

        // Then
        XCTAssertFalse(viewModel.shouldEnableDoneButton)

        // When
        viewModel.selectedLength = .init(title: "2", value: 2)

        // Then
        XCTAssertTrue(viewModel.shouldEnableDoneButton)
    }

    // MARK: Completion block

    func test_didTapDone_calls_completion_block_with_expected_values_when_no_changes_made() throws {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1",
                                                           period: .year,
                                                           periodInterval: "1")

        waitFor { promise in
            let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { length, hasUnsavedChanges in
                XCTAssertEqual(length, "1")
                XCTAssertEqual(hasUnsavedChanges, false)
                promise(())
            }

            // When
            viewModel.didTapDone()
        }
    }

    func test_didTapDone_calls_completion_block_with_expected_values_when_length_changed() throws {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1",
                                                           period: .year,
                                                           periodInterval: "1")

        waitFor { promise in
            let viewModel = SubscriptionExpiryViewModel(subscription: subscription) { length, hasUnsavedChanges in
                XCTAssertEqual(length, "5")
                XCTAssertEqual(hasUnsavedChanges, true)
                promise(())
            }

            // When
            viewModel.selectedLength = .init(title: "5 \(SubscriptionPeriod.day.descriptionPlural)",
                                             value: 5)
            viewModel.didTapDone()
        }
    }
}
