import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationSellingPlatformsQuestionViewModelTests: XCTestCase {
    func test_topHeader_is_set_to_store_name() throws {
        // Given
        let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store 🌟") { _ in }

        // Then
        XCTAssertEqual(viewModel.topHeader, "store 🌟")
    }

    func test_selecting_a_platform_adds_to_selectedPlatforms() throws {
        // Given
        let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") { _ in }
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
        let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") { _ in }
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

    func test_continueButtonTapped_invokes_onContinue_after_selecting_multiple_platforms() throws {
        let answer = waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") { answer in
                promise(answer)
            }

            // When
            viewModel.selectPlatform(.wordPress)
            viewModel.selectPlatform(.amazon)
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }

        // Then
        XCTAssertEqual(answer, .init(sellingStatus: .alreadySellingOnline, sellingPlatforms: [.wordPress, .amazon]))
    }

    func test_continueButtonTapped_invokes_onContinue_without_selecting_a_platform() throws {
        let answer = waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") { answer in
                promise(answer)
            }
            // When
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }

        // Then
        XCTAssertEqual(answer, .init(sellingStatus: .alreadySellingOnline, sellingPlatforms: []))
    }

    func test_skipButtonTapped_invokes_onContinue_with_empty_platforms() throws {
        let answer = waitFor { promise in
            // Given
            let viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: "store") { answer in
                promise(answer)
            }

            // When
            viewModel.skipButtonTapped()
        }

        // Then
        XCTAssertEqual(answer, .init(sellingStatus: .alreadySellingOnline, sellingPlatforms: []))
    }
}
