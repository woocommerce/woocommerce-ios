import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationCategoryQuestionViewModelTests: XCTestCase {
    func test_selectCategory_updates_selectedCategory() throws {
        // Given
        let viewModel = StoreCreationCategoryQuestionViewModel(storeName: "store",
                                                               onContinue: { _ in },
                                                               onSkip: {})

        // When
        viewModel.selectCategory(.init(name: "Cool clothing", value: "cool_clothing"))

        // Then
        XCTAssertEqual(viewModel.selectedCategory, .init(name: "Cool clothing", value: "cool_clothing"))
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_a_category() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationCategoryQuestionViewModel(storeName: "store",
                                                                   onContinue: { _ in
                // Then
                promise(())
            },
                                                                   onSkip: {})
            // When
            viewModel.selectCategory(.init(name: "Cool clothing", value: "cool_clothing"))
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }
    }

    func test_continueButtonTapped_invokes_onSkip_without_selecting_a_category() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationCategoryQuestionViewModel(storeName: "store",
                                                                   onContinue: { _ in },
                                                                   onSkip: {
                // Then
                promise(())
            })
            // When
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }
    }

    func test_skipButtonTapped_invokes_onSkip() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationCategoryQuestionViewModel(storeName: "store",
                                                                   onContinue: { _ in },
                                                                   onSkip: {
                // Then
                promise(())
            })
            // When
            viewModel.skipButtonTapped()
        }
    }
}
