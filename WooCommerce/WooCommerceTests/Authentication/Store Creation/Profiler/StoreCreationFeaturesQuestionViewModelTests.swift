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

            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }

        // Then
        XCTAssertEqual(answer, [.init(name: StoreCreationFeaturesQuestionViewModel.Feature.productManagementAndInventoryTracking.name,
                                      value: "product-management-and-inventory-tracking"),
                                .init(name: StoreCreationFeaturesQuestionViewModel.Feature.abilityToScaleAsBusinessGrows.name,
                                                              value: "ability-to-scale-as-business-grows")])
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
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
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

    func test_features_are_in_the_expected_order() throws {
        // Given
        let viewModel = StoreCreationFeaturesQuestionViewModel(onContinue: { _ in },
                                                               onSkip: {})

        // When
        let features = viewModel.features

        // Then
        XCTAssertEqual(features,
                       [
                        .salesAndAnalyticsReports,
                        .productManagementAndInventoryTracking,
                        .flexibleAndSecurePaymentOptions,
                        .inPersonPayment,
                        .abilityToScaleAsBusinessGrows,
                        .customisationOptionForStoreDesign,
                        .wideRangeOfPluginsAndExtensions,
                        .others,
                       ])
    }
}
