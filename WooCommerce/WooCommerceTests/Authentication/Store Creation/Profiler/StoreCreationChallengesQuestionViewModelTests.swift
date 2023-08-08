import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationChallengesQuestionViewModelTests: XCTestCase {
    func test_didTapChallenge_adds_challenge_to_selectedChallenges() throws {
        // Given
        let viewModel = StoreCreationChallengesQuestionViewModel(onContinue: { _ in },
                                                               onSkip: {})

        // When
        viewModel.didTapChallenge(.shippingAndLogistics)
        viewModel.didTapChallenge(.managingInventory)

        // Then
        XCTAssertEqual(viewModel.selectedChallenges, [.shippingAndLogistics, .managingInventory])
    }

    func test_didTapChallenge_removes_challenge_from_selectedChallenges_if_already_selected() throws {
        // Given
        let viewModel = StoreCreationChallengesQuestionViewModel(onContinue: { _ in },
                                                               onSkip: {})

        // When
        viewModel.didTapChallenge(.shippingAndLogistics)
        viewModel.didTapChallenge(.managingInventory)

        // Then
        XCTAssertEqual(viewModel.selectedChallenges, [.shippingAndLogistics, .managingInventory])

        // When
        viewModel.didTapChallenge(.shippingAndLogistics)

        // Then
        XCTAssertEqual(viewModel.selectedChallenges, [.managingInventory])
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_challenges() throws {
        let answer = waitFor { promise in
            // Given
            let viewModel = StoreCreationChallengesQuestionViewModel(onContinue: { answer in
                promise(answer)
            },
                                                                   onSkip: {})
            // When
            viewModel.didTapChallenge(.shippingAndLogistics)
            viewModel.didTapChallenge(.managingInventory)

            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }

        // Then
        XCTAssertEqual(answer, [.init(name: StoreCreationChallengesQuestionViewModel.Challenge.shippingAndLogistics.name,
                                     value: "shipping-and-logistics"),
                                .init(name: StoreCreationChallengesQuestionViewModel.Challenge.managingInventory.name,
                                                             value: "managing-inventory")])
    }

    func test_continueButtonTapped_invokes_onSkip_without_selecting_a_challenge() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationChallengesQuestionViewModel(    onContinue: { _ in },
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
            let viewModel = StoreCreationChallengesQuestionViewModel(    onContinue: { _ in },
                                                                   onSkip: {
                // Then
                promise(())
            })
            // When
            viewModel.skipButtonTapped()
        }
    }
}
