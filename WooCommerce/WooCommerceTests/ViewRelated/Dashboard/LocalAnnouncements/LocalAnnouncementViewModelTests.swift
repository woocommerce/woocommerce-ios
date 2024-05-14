import XCTest
import Yosemite
import protocol WooFoundation.Analytics
@testable import WooCommerce

final class LocalAnnouncementViewModelTests: XCTestCase {
    private var analytics: Analytics!
    private var analyticsProvider: MockAnalyticsProvider!
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    // MARK: Analytics

    func test_localAnnouncementDisplayed_is_tracked_when_the_view_appears() throws {
        // Given
        let viewModel = LocalAnnouncementViewModel(announcement: .productDescriptionAI, analytics: analytics)

        // When
        viewModel.onAppear()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["local_announcement_displayed"])
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(eventProperties["announcement"] as? String, "product_description_ai")
    }

    func test_localAnnouncementCallToActionTapped_is_tracked_when_the_cta_is_tapped() throws {
        // Given
        let viewModel = LocalAnnouncementViewModel(announcement: .productDescriptionAI, analytics: analytics)

        // When
        viewModel.ctaTapped()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["local_announcement_cta_tapped"])
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(eventProperties["announcement"] as? String, "product_description_ai")
    }

    func test_localAnnouncementDismissTapped_is_tracked_when_dismiss_is_tapped() throws {
        // Given
        let viewModel = LocalAnnouncementViewModel(announcement: .productDescriptionAI, analytics: analytics)

        // When
        viewModel.dismissTapped()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["local_announcement_dismissed"])
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(eventProperties["announcement"] as? String, "product_description_ai")
    }

    // MARK: Store actions

    func test_ctaTapped_dispatches_setLocalAnnouncementDismissed_action() throws {
        // Given
        let viewModel = LocalAnnouncementViewModel(announcement: .productDescriptionAI, stores: stores, analytics: analytics)

        // When
        waitFor { promise in
            self.stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
                guard case .setLocalAnnouncementDismissed = action else {
                    return XCTFail("Unexpected action: \(action)")
                }
                // Then
                promise(())
            }
            viewModel.ctaTapped()
        }
    }

    func test_dismissTapped_dispatches_setLocalAnnouncementDismissed_action() throws {
        // Given
        let viewModel = LocalAnnouncementViewModel(announcement: .productDescriptionAI, stores: stores, analytics: analytics)

        // When
        waitFor { promise in
            self.stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
                guard case .setLocalAnnouncementDismissed = action else {
                    return XCTFail("Unexpected action: \(action)")
                }
                // Then
                promise(())
            }
            viewModel.dismissTapped()
        }
    }
}
