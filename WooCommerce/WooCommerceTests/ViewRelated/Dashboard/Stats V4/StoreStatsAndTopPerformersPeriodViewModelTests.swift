import XCTest

@testable import WooCommerce

final class StoreStatsAndTopPerformersPeriodViewModelTest: XCTestCase {

    func test_isInAppFeedbackCardVisible_is_false_if_feature_flag_is_off() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: false)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService)

        // When
        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_true_if_feature_flag_is_on() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService)

        // When
        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_false_if_canDisplayInAppFeedbackCard_is_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: false,
                                                                  featureFlagService: featureFlagService)

        // When
        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }
}
