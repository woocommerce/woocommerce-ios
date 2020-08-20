import XCTest

@testable import WooCommerce
import Yosemite

/// Test cases for StoreStatsAndTopPerformersPeriodViewModel.
///
final class StoreStatsAndTopPerformersPeriodViewModelTests: XCTestCase {

    private var storesManager: MockupStoresManager!
    private var analyticsProvider: MockupAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        storesManager = MockupStoresManager(sessionManager: SessionManager.testingInstance)
        analyticsProvider = MockupAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        storesManager = nil
        super.tearDown()
    }

    func test_isInAppFeedbackCardVisible_is_false_by_default() {
        // When
        let viewModel = makeViewModel()

        var emittedValues = [Bool]()
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            emittedValues.append(value)
        }

        // Then
        XCTAssertEqual([false], emittedValues)
    }

    func test_isInAppFeedbackCardVisible_is_false_if_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: false)
        let viewModel = makeViewModel(featureFlagService: featureFlagService)

        var emittedValues = [Bool]()
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            emittedValues.append(value)
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual([false, false], emittedValues)
    }

    func test_isInAppFeedbackCardVisible_is_false_if_canDisplayInAppFeedbackCard_is_false() {
        // Given
        let viewModel = makeViewModel(canDisplayInAppFeedbackCard: false)

        var emittedValues = [Bool]()
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            emittedValues.append(value)
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual([false, false], emittedValues)
    }

    func test_isInAppFeedbackCardVisible_is_true_if_the_AppSettingsAction_returns_true() {
        // Given
        let viewModel = makeViewModel()

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadFeedbackVisibility(_, onCompletion) = action {
                onCompletion(.success(true))
            }
        }

        var emittedValues = [Bool]()
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            emittedValues.append(value)
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual([false, true], emittedValues)
    }

    func test_isInAppFeedbackCardVisible_is_false_if_the_AppSettingsAction_returns_false() {
        // Given
        let viewModel = makeViewModel()

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadFeedbackVisibility(_, onCompletion) = action {
                onCompletion(.success(false))
            }
        }

        var emittedValues = [Bool]()
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            emittedValues.append(value)
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual([false, false], emittedValues)
    }

    func test_isInAppFeedbackCardVisible_is_false_if_the_AppSettingsAction_returns_an_error() {
        // Given
        let viewModel = makeViewModel()

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadFeedbackVisibility(_, onCompletion) = action {
                onCompletion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
            }
        }

        var emittedValues = [Bool]()
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            emittedValues.append(value)
        }

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual([false, false], emittedValues)
    }

    func test_isInAppFeedbackCardVisible_is_recomputed_on_viewDidAppear() throws {
        // Given
        let viewModel = makeViewModel()

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadFeedbackVisibility(_, onCompletion) = action {
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

    func test_isInAppFedbackCardVisible_is_false_after_tapping_on_card_CTAs() {
        // Given
        let viewModel = makeViewModel()

        // Default `loadInAppFeedbackCardVisibility` to true until `setLastFeedbackDate` action sets it to `false`
        var shouldShowFeedbackCard = true
        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadFeedbackVisibility(_, onCompletion) = action {
                onCompletion(.success(shouldShowFeedbackCard))
            }

            if case let AppSettingsAction.updateFeedbackStatus(_, _, onCompletion) = action {
                shouldShowFeedbackCard = false
                onCompletion(.success(Void()))
            }
        }

        // When
        var emittedValues = [Bool]()
        _ = viewModel.isInAppFeedbackCardVisible.subscribe { value in
            emittedValues.append(value)
        }

        viewModel.onViewDidAppear()
        viewModel.onInAppFeedbackCardAction()

        // Then
        XCTAssertEqual([false, true, false], emittedValues)
    }
}

private extension StoreStatsAndTopPerformersPeriodViewModelTests {
    func makeViewModel(canDisplayInAppFeedbackCard: Bool = true,
                       featureFlagService: MockFeatureFlagService = .init(isInAppFeedbackOn: true)) -> StoreStatsAndTopPerformersPeriodViewModel {
        StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: canDisplayInAppFeedbackCard,
                                                  featureFlagService: featureFlagService,
                                                  storesManager: storesManager,
                                                  analytics: analytics)
    }
}
