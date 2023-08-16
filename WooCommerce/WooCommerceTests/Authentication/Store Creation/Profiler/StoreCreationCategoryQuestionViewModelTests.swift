import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationCategoryQuestionViewModelTests: XCTestCase {
    func test_selectCategory_updates_selectedCategory() throws {
        // Given
        let viewModel = StoreCreationCategoryQuestionViewModel(onContinue: { _ in },
                                                               onSkip: {})

        // When
        viewModel.selectCategory(.clothingAccessories)

        // Then
        XCTAssertEqual(viewModel.selectedCategory, .clothingAccessories)
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_a_category() throws {
        let answer = waitFor { promise in
            // Given
            let viewModel = StoreCreationCategoryQuestionViewModel(onContinue: { answer in
                promise(answer)
            },
                                                                   onSkip: {})
            // When
            viewModel.selectCategory(.clothingAccessories)
            viewModel.continueButtonTapped()
        }

        // Then
        XCTAssertEqual(answer, .init(name: StoreCreationCategoryQuestionViewModel.Category.clothingAccessories.name,
                                     value: "clothing_and_accessories"))
    }

    func test_continueButtonTapped_invokes_onSkip_without_selecting_a_category() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationCategoryQuestionViewModel(onContinue: { _ in },
                                                                   onSkip: {
                // Then
                promise(())
            })
            // When
            viewModel.continueButtonTapped()
        }
    }

    func test_skipButtonTapped_invokes_onSkip() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationCategoryQuestionViewModel(onContinue: { _ in },
                                                                   onSkip: {
                // Then
                promise(())
            })
            // When
            viewModel.skipButtonTapped()
        }
    }

    func test_categories_are_in_the_expected_order() throws {
        // Given
        let viewModel = StoreCreationCategoryQuestionViewModel(onContinue: { _ in },
                                                               onSkip: {})

        // When
        let categories = viewModel.categories

        // Then
        XCTAssertEqual(categories,
                       [.clothingAccessories,
                        .healthBeauty,
                        .foodDrink,
                        .homeFurnitureGarden,
                        .educationAndLearning,
                        .electronicsComputers,
                        .other
                       ])
    }
}
