import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationSellingStatusQuestionViewModelTests: XCTestCase {
    func test_selectCategory_updates_selectedStatus() throws {
        // Given
        let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") {} onSkip: {}

        // When
        viewModel.selectStatus(.alreadySellingOnline)

        // Then
        XCTAssertEqual(viewModel.selectedStatus, .alreadySellingOnline)
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_a_status() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") {
                // Then
                promise(())
            } onSkip: {}
            // When
            viewModel.selectStatus(.alreadySellingButNotOnline)
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }
    }

    func test_continueButtonTapped_invokes_onSkip_without_selecting_a_category() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") {} onSkip: {
                // Then
                promise(())
            }
            // When
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }
    }

    func test_skipButtonTapped_invokes_onSkip() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") {} onSkip: {
                // Then
                promise(())
            }
            // When
            viewModel.skipButtonTapped()
        }
    }
}
