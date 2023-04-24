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
        viewModel.selectCategory(.fashionApparelAccessories)

        // Then
        XCTAssertEqual(viewModel.selectedCategory, .fashionApparelAccessories)
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_a_category() throws {
        let answer = waitFor { promise in
            // Given
            let viewModel = StoreCreationCategoryQuestionViewModel(storeName: "store",
                                                                   onContinue: { answer in
                promise(answer)
            },
                                                                   onSkip: {})
            // When
            viewModel.selectCategory(.fashionApparelAccessories)
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }

        // Then
        XCTAssertEqual(answer, .init(name: StoreCreationCategoryQuestionViewModel.Category.fashionApparelAccessories.name,
                                     value: "fashion-apparel-accessories"))
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

    func test_categories_are_in_the_expected_order() throws {
        // Given
        let viewModel = StoreCreationCategoryQuestionViewModel(storeName: "store",
                                                               onContinue: { _ in },
                                                               onSkip: {})

        // When
        let categories = viewModel.categories

        // Then
        XCTAssertEqual(categories,
                       [.fashionApparelAccessories,
                        .healthBeauty,
                        .foodDrink,
                        .homeFurnitureGarden,
                        .educationAndLearning,
                        .electronicsComputers,
                        .other
                       ])
    }
}
