import XCTest
@testable import WooCommerce
import Yosemite

@MainActor
final class POSPromotionViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var sessionManager: SessionManager!
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sessionManager = SessionManager.testingInstance
        sessionManager.defaultStoreID = 123
        stores = MockStoresManager(sessionManager: sessionManager)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        stores = nil
        sessionManager = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initial_selectedStep_is_zero() {
        // Given
        let sut = makeSUT()

        // Then
        XCTAssertEqual(sut.selectedStep, 0)
    }

    func test_steps_are_loaded_from_factory() {
        // Given
        let sut = makeSUT()

        // Then
        XCTAssertEqual(sut.totalSteps, 5)
    }

    func test_isOnFinalStep_is_false_when_on_first_step() {
        // Given
        let sut = makeSUT()

        // Then
        XCTAssertFalse(sut.isOnFinalStep)
    }

    func test_primaryButtonTitle_is_Next_when_not_on_final_step() {
        // Given
        let sut = makeSUT()

        // Then
        XCTAssertEqual(sut.primaryButtonTitle, "Next")
    }

    // MARK: - Primary Action

    func test_primaryActionTapped_advances_to_next_step_when_not_on_final_step() {
        // Given
        let sut = makeSUT()
        XCTAssertEqual(sut.selectedStep, 0)

        // When
        sut.primaryActionTapped()

        // Then
        XCTAssertEqual(sut.selectedStep, 1)
    }

    func test_primaryActionTapped_calls_onShowWebView_and_dismisses_when_on_final_step() {
        // Given
        var receivedWebViewModel: WebViewSheetViewModel?
        let sut = makeSUT(onShowWebView: { webViewModel in
            receivedWebViewModel = webViewModel
        })

        // Navigate to final step
        for _ in 0..<4 {
            sut.primaryActionTapped()
        }
        XCTAssertTrue(sut.isOnFinalStep)
        XCTAssertNil(receivedWebViewModel)

        // When
        sut.primaryActionTapped()

        // Then
        XCTAssertNotNil(receivedWebViewModel)
        XCTAssertTrue(receivedWebViewModel?.url.absoluteString.contains(WooConstants.URLs.posLearnMore.rawValue) == true)
        XCTAssertTrue(receivedWebViewModel?.url.absoluteString.contains("utm_") == true)
        XCTAssertTrue(sut.dismiss)
    }

    func test_primaryButtonTitle_is_Explore_WooCommerce_POS_when_on_final_step() {
        // Given
        let sut = makeSUT()

        // Navigate to final step
        for _ in 0..<4 {
            sut.primaryActionTapped()
        }

        // Then
        XCTAssertEqual(sut.primaryButtonTitle, "Explore WooCommerce POS")
    }

    // MARK: - Close Button

    func test_closeButtonTapped_sets_dismiss_to_true() {
        // Given
        let sut = makeSUT()

        // When
        sut.closeButtonTapped()

        // Then
        XCTAssertTrue(sut.dismiss)
    }

    // MARK: - Analytics

    func test_onAppear_tracks_modal_viewed_event() {
        // Given
        let sut = makeSUT()

        // When
        sut.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promo_modal_viewed"))
    }

    func test_onAppear_tracks_initial_slide_viewed_event_with_index_zero() {
        // Given
        let sut = makeSUT()

        // When
        sut.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promo_modal_slide_viewed"))
        // The slide_viewed event is second (after modal_viewed), so its properties are at index 0
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["slide_index"] as? Int, 0)
    }

    func test_primaryActionTapped_tracks_slide_viewed_event_with_new_index() {
        // Given
        let sut = makeSUT()
        sut.onAppear()
        analyticsProvider.clearEvents()

        // When
        sut.primaryActionTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promo_modal_slide_viewed"))
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["slide_index"] as? Int, 1)
    }

    func test_swiping_to_new_slide_tracks_slide_viewed_event() {
        // Given
        let sut = makeSUT()
        sut.onAppear()
        analyticsProvider.clearEvents()

        // When - simulate swiping by directly changing selectedStep
        sut.selectedStep = 3

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promo_modal_slide_viewed"))
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["slide_index"] as? Int, 3)
    }

    func test_onDisappear_tracks_dismissed_event() {
        // Given
        let sut = makeSUT()

        // When
        sut.onDisappear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promo_modal_dismissed"))
    }

    func test_onDisappear_does_not_track_dismissed_event_after_explore_tapped() {
        // Given
        let sut = makeSUT()

        // Navigate to final step and tap explore
        for _ in 0..<4 {
            sut.primaryActionTapped()
        }
        sut.primaryActionTapped()
        analyticsProvider.clearEvents()

        // When
        sut.onDisappear()

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("pos_promo_modal_dismissed"))
    }

    func test_primaryActionTapped_on_final_step_tracks_explore_clicked_event() {
        // Given
        let sut = makeSUT()

        // Navigate to final step
        for _ in 0..<4 {
            sut.primaryActionTapped()
        }

        // When
        sut.primaryActionTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promo_modal_explore_clicked"))
    }

    // MARK: - onDismiss callback

    func test_onDisappear_calls_onDismiss_callback() {
        // Given
        var onDismissCalled = false
        let sut = makeSUT(onDismiss: { onDismissCalled = true })

        // When
        sut.onDisappear()

        // Then
        XCTAssertTrue(onDismissCalled)
    }
}

// MARK: - Helpers

private extension POSPromotionViewModelTests {
    func makeSUT(onDismiss: @escaping () -> Void = {},
                 onShowWebView: @escaping (WebViewSheetViewModel) -> Void = { _ in }) -> POSPromotionViewModel {
        POSPromotionViewModel(
            analytics: analytics,
            stores: stores,
            onDismiss: onDismiss,
            onShowWebView: onShowWebView
        )
    }
}
