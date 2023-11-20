import XCTest
import Yosemite
@testable import WooCommerce
import WooFoundation

final class SubscriptionTrialViewModelTests: XCTestCase {
    private let samplePeriod: SubscriptionPeriod = .month

    // MARK: `trialPeriodDescription`

    func test_trialPeriodDescription_returns_expected_description_for_singular_trialPeriod_interval() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "1", trialPeriod: samplePeriod)
        let viewModel = SubscriptionTrialViewModel(subscription: subscription) { _, _, _ in }

        // Then
        XCTAssertEqual(viewModel.trialPeriodDescription, samplePeriod.descriptionSingular)
    }

    func test_trialPeriodDescription_returns_expected_description_for_plural_trialPeriod_interval() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "2", trialPeriod: samplePeriod)
        let viewModel = SubscriptionTrialViewModel(subscription: subscription) { _, _, _ in }

        // Then
        XCTAssertEqual(viewModel.trialPeriodDescription, samplePeriod.descriptionPlural)
    }

    // MARK: Completion block

    func test_didTapDone_fires_completion_block_with_expected_values_when_no_changes_made() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "1", trialPeriod: samplePeriod)

        var trialLength: String?
        var trialPeriod: SubscriptionPeriod?
        var hasUnsavedChanges: Bool?

        waitFor { promise in
            let viewModel = SubscriptionTrialViewModel(subscription: subscription) {
                trialLength = $0
                trialPeriod = $1
                hasUnsavedChanges = $2
                promise(())
            }

            // When
            viewModel.didTapDone()
        }

        // Then
        XCTAssertEqual(trialLength, "1")
        XCTAssertEqual(trialPeriod, samplePeriod)
        XCTAssertEqual(hasUnsavedChanges, false)
    }

    func test_didTapDone_fires_completion_block_with_expected_values_when_trial_length_changed() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "1", trialPeriod: samplePeriod)

        var trialLength: String?
        var trialPeriod: SubscriptionPeriod?
        var hasUnsavedChanges: Bool?

        waitFor { promise in
            let viewModel = SubscriptionTrialViewModel(subscription: subscription) {
                trialLength = $0
                trialPeriod = $1
                hasUnsavedChanges = $2
                promise(())
            }
            // Confidence check
            viewModel.trialLength = "4"

            // When
            viewModel.didTapDone()
        }

        // Then
        XCTAssertEqual(trialLength, "4")
        XCTAssertEqual(trialPeriod, samplePeriod)
        XCTAssertEqual(hasUnsavedChanges, true)
    }

    func test_didTapDone_fires_completion_block_with_expected_values_when_trial_period_changed() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "1", trialPeriod: samplePeriod)

        var trialLength: String?
        var trialPeriod: SubscriptionPeriod?
        var hasUnsavedChanges: Bool?

        waitFor { promise in
            let viewModel = SubscriptionTrialViewModel(subscription: subscription) {
                trialLength = $0
                trialPeriod = $1
                hasUnsavedChanges = $2
                promise(())
            }
            // Confidence check
            viewModel.trialPeriod = .day

            // When
            viewModel.didTapDone()
        }

        // Then
        XCTAssertEqual(trialLength, "1")
        XCTAssertEqual(trialPeriod, .day)
        XCTAssertEqual(hasUnsavedChanges, true)
    }

    func test_didTapDone_fires_completion_block_with_expected_values_when_trial_period_changed_but_trial_length_remains_zero() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "0", trialPeriod: .day)

        var trialLength: String?
        var trialPeriod: SubscriptionPeriod?
        var hasUnsavedChanges: Bool?

        waitFor { promise in
            let viewModel = SubscriptionTrialViewModel(subscription: subscription) {
                trialLength = $0
                trialPeriod = $1
                hasUnsavedChanges = $2
                promise(())
            }
            // Confidence check
            viewModel.trialPeriod = .month

            // When
            viewModel.didTapDone()
        }

        // Then
        XCTAssertEqual(trialLength, "0")
        XCTAssertEqual(trialPeriod, .month)
        XCTAssertEqual(hasUnsavedChanges, false)
    }

    // MARK: `isInputValid`

    func test_isInputValid_turns_false_when_day_limit_exceeds() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "\(Int.random(in: 1..<90))", trialPeriod: .day)
        let viewModel = SubscriptionTrialViewModel(subscription: subscription) { _, _, _ in }

        XCTAssertTrue(viewModel.isInputValid)

        // When
        viewModel.trialLength = "91"

        // Then
        XCTAssertFalse(viewModel.isInputValid)
    }

    func test_isInputValid_turns_false_when_week_limit_exceeds() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "\(Int.random(in: 1..<52))", trialPeriod: .week)
        let viewModel = SubscriptionTrialViewModel(subscription: subscription) { _, _, _ in }

        XCTAssertTrue(viewModel.isInputValid)

        // When
        viewModel.trialLength = "53"

        // Then
        XCTAssertFalse(viewModel.isInputValid)
    }

    func test_isInputValid_turns_false_when_month_limit_exceeds() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "\(Int.random(in: 1..<24))", trialPeriod: .month)
        let viewModel = SubscriptionTrialViewModel(subscription: subscription) { _, _, _ in }

        XCTAssertTrue(viewModel.isInputValid)

        // When
        viewModel.trialLength = "25"

        // Then
        XCTAssertFalse(viewModel.isInputValid)
    }

    func test_isInputValid_turns_false_when_year_limit_exceeds() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "\(Int.random(in: 1..<5))", trialPeriod: .year)
        let viewModel = SubscriptionTrialViewModel(subscription: subscription) { _, _, _ in }

        XCTAssertTrue(viewModel.isInputValid)

        // When
        viewModel.trialLength = "6"

        // Then
        XCTAssertFalse(viewModel.isInputValid)
    }
}
