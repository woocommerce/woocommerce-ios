import XCTest
@testable import WooCommerce

@MainActor
final class POSPromotionViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
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

    func test_primaryActionTapped_opens_URL_and_dismisses_when_on_final_step() {
        // Given
        var openedURL: URL?
        let urlOpener = MockURLOpener { url in
            openedURL = url
        }
        let sut = makeSUT(urlOpener: urlOpener)

        // Navigate to final step
        for _ in 0..<4 {
            sut.primaryActionTapped()
        }
        XCTAssertTrue(sut.isOnFinalStep)

        // When
        sut.primaryActionTapped()

        // Then
        XCTAssertEqual(openedURL, WooConstants.URLs.posLearnMore.asURL())
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

    func test_onAppear_tracks_modal_shown_event() {
        // Given
        let sut = makeSUT()

        // When
        sut.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promotion_modal_shown"))
    }

    func test_closeButtonTapped_tracks_modal_dismissed_event() {
        // Given
        let sut = makeSUT()

        // When
        sut.closeButtonTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promotion_modal_dismissed"))
    }

    func test_primaryActionTapped_on_final_step_tracks_cta_tapped_event() {
        // Given
        let sut = makeSUT()

        // Navigate to final step
        for _ in 0..<4 {
            sut.primaryActionTapped()
        }

        // When
        sut.primaryActionTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("pos_promotion_modal_cta_tapped"))
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
    func makeSUT(urlOpener: URLOpener = MockURLOpener(open: { _ in }),
                 onDismiss: @escaping () -> Void = {}) -> POSPromotionViewModel {
        POSPromotionViewModel(
            analytics: analytics,
            urlOpener: urlOpener,
            onDismiss: onDismiss
        )
    }
}
