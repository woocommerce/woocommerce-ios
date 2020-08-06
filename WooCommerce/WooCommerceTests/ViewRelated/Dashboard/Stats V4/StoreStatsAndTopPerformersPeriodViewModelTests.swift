import XCTest

@testable import WooCommerce
import Yosemite

final class StoreStatsAndTopPerformersPeriodViewModelTest: XCTestCase {

    private var storesManager: MockupStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockupStoresManager(sessionManager: SessionManager.testingInstance)
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    func test_isInAppFeedbackCardVisible_is_false_if_feature_flag_is_off() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: false)

        // When
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService)

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_false_if_canDisplayInAppFeedbackCard_is_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)

        // When
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: false,
                                                                  featureFlagService: featureFlagService)

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_true_if_the_AppSettingsAction_returns_true() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadInAppFeedbackCardVisibility(onCompletion) = action {
                onCompletion(.success(true))
            }
        }

        // When
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService,
                                                                  storesManager: storesManager)

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_false_if_the_AppSettingsAction_returns_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadInAppFeedbackCardVisibility(onCompletion) = action {
                onCompletion(.success(false))
            }
        }

        // When
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService,
                                                                  storesManager: storesManager)

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_false_if_the_AppSettingsAction_returns_an_error() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadInAppFeedbackCardVisibility(onCompletion) = action {
                onCompletion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
            }
        }

        // When
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService,
                                                                  storesManager: storesManager)

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }
}
