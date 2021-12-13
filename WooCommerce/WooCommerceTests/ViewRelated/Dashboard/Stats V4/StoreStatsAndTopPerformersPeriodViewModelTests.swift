import XCTest
import TestKit

@testable import WooCommerce
import Yosemite

/// Test cases for StoreStatsAndTopPerformersPeriodViewModel.
///
final class StoreStatsAndTopPerformersPeriodViewModelTests: XCTestCase {

    private var storesManager: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
        analyticsProvider = MockAnalyticsProvider()
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
        assertEmpty(analyticsProvider.receivedProperties)
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
        assertEmpty(analyticsProvider.receivedProperties)
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

    func test_shown_event_action_is_tracked_when_isInAppFeedbackCardVisible_returns_true() throws {
        // Given
        let viewModel = makeViewModel()

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let AppSettingsAction.loadFeedbackVisibility(_, onCompletion) = action {
                onCompletion(.success(true))
            }
        }

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "app_feedback_prompt")

        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch["action"] as? String, "shown")
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
        assertEmpty(analyticsProvider.receivedProperties)
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
        assertEmpty(analyticsProvider.receivedProperties)
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
    func makeViewModel(canDisplayInAppFeedbackCard: Bool = true) -> StoreStatsAndTopPerformersPeriodViewModel {
        StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: canDisplayInAppFeedbackCard,
                                                  storesManager: storesManager,
                                                  analytics: analytics)
    }
}
