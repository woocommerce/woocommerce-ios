import XCTest
@testable import WooCommerce

@MainActor
final class POSPromotionViewModelTests: XCTestCase {

    // MARK: - Initial State

    func test_initial_selectedStep_is_zero() {
        // Given
        let sut = makeSUT()

        // Then
        XCTAssertEqual(sut.selectedStep, 0)
    }

    func test_steps_are_loaded_from_factory() {
        // Given
        let sut = makeSUT()

        // Then
        XCTAssertEqual(sut.totalSteps, 5)
    }

    func test_isOnFinalStep_is_false_when_on_first_step() {
        // Given
        let sut = makeSUT()

        // Then
        XCTAssertFalse(sut.isOnFinalStep)
    }

    func test_primaryButtonTitle_is_Next_when_not_on_final_step() {
        // Given
        let sut = makeSUT()

        // Then
        XCTAssertEqual(sut.primaryButtonTitle, "Next")
    }

    // MARK: - Primary Action

    func test_primaryActionTapped_advances_to_next_step_when_not_on_final_step() {
        // Given
        let sut = makeSUT()
        XCTAssertEqual(sut.selectedStep, 0)

        // When
        sut.primaryActionTapped()

        // Then
        XCTAssertEqual(sut.selectedStep, 1)
    }

    func test_primaryActionTapped_dismisses_when_on_final_step() {
        // Given
        let sut = makeSUT()

        // Navigate to final step
        for _ in 0..<4 {
            sut.primaryActionTapped()
        }
        XCTAssertTrue(sut.isOnFinalStep)

        // When
        sut.primaryActionTapped()

        // Then
        XCTAssertTrue(sut.dismiss)
    }

    func test_primaryButtonTitle_is_Explore_WooCommerce_POS_when_on_final_step() {
        // Given
        let sut = makeSUT()

        // Navigate to final step
        for _ in 0..<4 {
            sut.primaryActionTapped()
        }

        // Then
        XCTAssertEqual(sut.primaryButtonTitle, "Explore WooCommerce POS")
    }

    // MARK: - Close Button

    func test_closeButtonTapped_sets_dismiss_to_true() {
        // Given
        let sut = makeSUT()

        // When
        sut.closeButtonTapped()

        // Then
        XCTAssertTrue(sut.dismiss)
    }

    // MARK: - onDismiss callback

    func test_onDisappear_calls_onDismiss_callback() {
        // Given
        var onDismissCalled = false
        let sut = makeSUT(onDismiss: { onDismissCalled = true })

        // When
        sut.onDisappear()

        // Then
        XCTAssertTrue(onDismissCalled)
    }
}

// MARK: - Helpers

private extension POSPromotionViewModelTests {
    func makeSUT(onDismiss: @escaping () -> Void = {}) -> POSPromotionViewModel {
        POSPromotionViewModel(onDismiss: onDismiss)
    }
}
