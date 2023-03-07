import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationSellingStatusQuestionViewModelTests: XCTestCase {
    func test_selecting_non_alreadySellingOnline_updates_selectedStatus_and_not_isAlreadySellingOnline() throws {
        // Given
        let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") { _ in } onSkip: {}
        XCTAssertFalse(viewModel.isAlreadySellingOnline)

        // When
        viewModel.selectStatus(.alreadySellingButNotOnline)

        // Then
        XCTAssertEqual(viewModel.selectedStatus, .alreadySellingButNotOnline)
        XCTAssertFalse(viewModel.isAlreadySellingOnline)
    }

    func test_selecting_alreadySellingOnline_updates_selectedStatus_and_isAlreadySellingOnline() throws {
        // Given
        let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") { _ in } onSkip: {}
        XCTAssertFalse(viewModel.isAlreadySellingOnline)

        // When
        viewModel.selectStatus(.alreadySellingOnline)

        // Then
        XCTAssertEqual(viewModel.selectedStatus, .alreadySellingOnline)
        XCTAssertTrue(viewModel.isAlreadySellingOnline)
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_a_non_alreadySellingOnline_status() throws {
        let answer = waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") { answer in
                promise(answer)
            } onSkip: {}
            // When
            viewModel.selectStatus(.alreadySellingButNotOnline)
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }

        // Then
        XCTAssertEqual(answer, .init(sellingStatus: .alreadySellingButNotOnline, sellingPlatforms: nil))
    }

    func test_continueButtonTapped_does_not_invoke_onContinue_after_selecting_alreadySellingOnline_status() throws {
        // Given
        let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") { _ in
            XCTFail("onContinue should not be invoked after selecting alreadySellingOnline status.")
        } onSkip: {}

        // When
        viewModel.selectStatus(.alreadySellingOnline)
        Task { @MainActor in
            await viewModel.continueButtonTapped()
        }
    }

    func test_continueButtonTapped_invokes_onSkip_without_selecting_a_category() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") { _ in } onSkip: {
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
            let viewModel = StoreCreationSellingStatusQuestionViewModel(storeName: "store") { _ in } onSkip: {
                // Then
                promise(())
            }
            // When
            viewModel.skipButtonTapped()
        }
    }
}
