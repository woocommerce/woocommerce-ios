import XCTest
@testable import WooCommerce

final class NotificationServiceSuppressionTests: XCTestCase {
    private var defaults: UserDefaults!
    private var state: PushNotificationRegistrationState!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "NotificationServiceSuppressionTests")
        defaults.removePersistentDomain(forName: "NotificationServiceSuppressionTests")
        state = PushNotificationRegistrationState(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "NotificationServiceSuppressionTests")
        defaults = nil
        state = nil
        super.tearDown()
    }

    // MARK: - shouldSuppressWPComNotification

    func test_shouldSuppress_returns_true_when_site_is_registered_and_both_keys_present() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        XCTAssertTrue(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_site_is_not_registered() {
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_noteID_is_missing() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(42)]

        XCTAssertFalse(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_siteID_is_missing() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_userInfo_is_empty() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = [:]

        XCTAssertFalse(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_siteID_is_wrong_type() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": "42", "note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_for_different_registered_site() {
        state.markSiteAsRegisteredForWooPNs(99)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_true_for_one_of_multiple_registered_sites() {
        state.markSiteAsRegisteredForWooPNs(10)
        state.markSiteAsRegisteredForWooPNs(20)
        state.markSiteAsRegisteredForWooPNs(30)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(20), "note_id": Int64(5)]

        XCTAssertTrue(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_after_site_is_unregistered() {
        state.markSiteAsRegisteredForWooPNs(42)
        state.unmarkSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppressWPComNotification(userInfo: userInfo))
    }
}
