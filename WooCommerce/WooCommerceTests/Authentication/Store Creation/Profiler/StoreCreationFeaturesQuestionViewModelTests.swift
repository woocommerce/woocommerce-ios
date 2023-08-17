import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationFeaturesQuestionViewModelTests: XCTestCase {
    func test_didTapFeature_adds_feature_to_selectedFeatures() throws {
        // Given
        let viewModel = StoreCreationFeaturesQuestionViewModel(onContinue: { _ in },
                                                               onSkip: {})

        // When
        viewModel.didTapFeature(.productManagementAndInventoryTracking)
        viewModel.didTapFeature(.abilityToScaleAsBusinessGrows)

        // Then
        XCTAssertEqual(viewModel.selectedFeatures, [.productManagementAndInventoryTracking, .abilityToScaleAsBusinessGrows])
    }

    func test_didTapFeature_removes_feature_from_selectedFeatures_if_already_selected() throws {
        // Given
        let viewModel = StoreCreationFeaturesQuestionViewModel(onContinue: { _ in },
                                                               onSkip: {})

        // When
        viewModel.didTapFeature(.productManagementAndInventoryTracking)
        viewModel.didTapFeature(.abilityToScaleAsBusinessGrows)

        // Then
        XCTAssertEqual(viewModel.selectedFeatures, [.productManagementAndInventoryTracking, .abilityToScaleAsBusinessGrows])

        // When
        viewModel.didTapFeature(.productManagementAndInventoryTracking)

        // Then
        XCTAssertEqual(viewModel.selectedFeatures, [.abilityToScaleAsBusinessGrows])
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_features() throws {
        let answer = waitFor { promise in
            // Given
            let viewModel = StoreCreationFeaturesQuestionViewModel(onContinue: { answer in
                promise(answer)
            },
                                                                   onSkip: {})
            // When
            viewModel.didTapFeature(.productManagementAndInventoryTracking)
            viewModel.didTapFeature(.abilityToScaleAsBusinessGrows)

            viewModel.continueButtonTapped()
        }

        // Then
        XCTAssertEqual(answer, [.init(name: StoreCreationFeaturesQuestionViewModel.Feature.productManagementAndInventoryTracking.name,
                                      value: "product_management_and_inventory"),
                                .init(name: StoreCreationFeaturesQuestionViewModel.Feature.abilityToScaleAsBusinessGrows.name,
                                                              value: "scale_as_business_grows")])
    }

    func test_continueButtonTapped_invokes_onSkip_without_selecting_a_feature() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationFeaturesQuestionViewModel(    onContinue: { _ in },
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
            let viewModel = StoreCreationFeaturesQuestionViewModel(    onContinue: { _ in },
                                                                       onSkip: {
                // Then
                promise(())
            })
            // When
            viewModel.skipButtonTapped()
        }
    }
}
