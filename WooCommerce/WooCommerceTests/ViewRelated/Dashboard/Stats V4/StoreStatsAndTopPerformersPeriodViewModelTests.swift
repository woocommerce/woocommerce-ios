import XCTest

@testable import WooCommerce
import Yosemite

/// Test cases for StoreStatsAndTopPerformersPeriodViewModel.
///
final class StoreStatsAndTopPerformersPeriodViewModelTests: XCTestCase {

    private var storesManager: MockupStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockupStoresManager(sessionManager: SessionManager.testingInstance)
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    func test_isInAppFeedbackCardVisible_is_false_by_default() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)

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

    func test_isInAppFeedbackCardVisible_is_false_if_feature_flag_is_off() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: false)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService)

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_false_if_canDisplayInAppFeedbackCard_is_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: false,
                                                                  featureFlagService: featureFlagService)

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_true_if_the_AppSettingsAction_returns_true() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService,
                                                                  storesManager: storesManager)

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadInAppFeedbackCardVisibility(onCompletion) = action {
                onCompletion(.success(true))
            }
        }

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertTrue(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_false_if_the_AppSettingsAction_returns_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService,
                                                                  storesManager: storesManager)

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadInAppFeedbackCardVisibility(onCompletion) = action {
                onCompletion(.success(false))
            }
        }

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_false_if_the_AppSettingsAction_returns_an_error() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService,
                                                                  storesManager: storesManager)

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadInAppFeedbackCardVisibility(onCompletion) = action {
                onCompletion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
            }
        }

        var isVisible: Bool?
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            isVisible = value
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertFalse(try XCTUnwrap(isVisible))
    }

    func test_isInAppFeedbackCardVisible_is_recomputed_on_viewDidAppear() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)
        let viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: true,
                                                                  featureFlagService: featureFlagService,
                                                                  storesManager: storesManager)

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadInAppFeedbackCardVisibility(onCompletion) = action {
                onCompletion(.success(true))
            }
        }

        var emittedValues = [Bool]()
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            emittedValues.append(value)
        }

        // When
        viewModel.onViewDidAppear()
        viewModel.onViewDidAppear()

        // Then
        // We should receive 3 values. The first is from the first subscription. The rest is
        // from the `onViewDidAppear()` calls.
        XCTAssertEqual([false, true, true], emittedValues)
    }
}
