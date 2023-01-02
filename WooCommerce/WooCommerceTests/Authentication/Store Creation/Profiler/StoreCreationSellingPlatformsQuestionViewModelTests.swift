import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationSellingPlatformsQuestionViewModelTests: XCTestCase {
    func test_topHeader_is_set_to_store_name() throws {
        // Given
        let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store 🌟") {} onSkip: {}

        // Then
        XCTAssertEqual(viewModel.topHeader, "store 🌟")
    }

    func test_selecting_a_platform_adds_to_selectedPlatforms() throws {
        // Given
        let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") {} onSkip: {}
        XCTAssertEqual(viewModel.selectedPlatforms, [])

        // When
        viewModel.selectPlatform(.wordPress)

        // Then
        XCTAssertEqual(viewModel.selectedPlatforms, [.wordPress])

        // When
        viewModel.selectPlatform(.amazon)

        // Then
        XCTAssertEqual(viewModel.selectedPlatforms, [.wordPress, .amazon])
    }

    func test_selecting_a_platform_twice_removes_platform_from_selectedPlatforms() throws {
        // Given
        let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") {} onSkip: {}
        XCTAssertEqual(viewModel.selectedPlatforms, [])

        // When
        viewModel.selectPlatform(.wordPress)

        // Then
        XCTAssertEqual(viewModel.selectedPlatforms, [.wordPress])

        // When
        viewModel.selectPlatform(.wordPress)

        // Then
        XCTAssertEqual(viewModel.selectedPlatforms, [])
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_a_platform() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") {
                // Then
                promise(())
            } onSkip: {}

            // When
            viewModel.selectPlatform(.wordPress)
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }
    }

    func test_continueButtonTapped_invokes_onContinue_without_selecting_a_category() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") {
                // Then
                promise(())
            } onSkip: {}
            // When
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }
    }

    func test_skipButtonTapped_invokes_onSkip() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") {} onSkip: {
                // Then
                promise(())
            }
            // When
            viewModel.skipButtonTapped()
        }
    }
}
