import XCTest
import struct NetworkingCore.Note
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

    // MARK: - Unknown notification type gate (RSM-3048)

    func test_isKnownNotificationType_returns_true_when_type_is_missing() {
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42)]

        XCTAssertTrue(PushNotificationSharedConstants.isKnownNotificationType(in: userInfo))
    }

    func test_isKnownNotificationType_returns_true_for_store_order() {
        let userInfo: [AnyHashable: Any] = ["type": "store_order", "blog": Int64(42)]

        XCTAssertTrue(PushNotificationSharedConstants.isKnownNotificationType(in: userInfo))
    }

    func test_isKnownNotificationType_returns_true_for_badge_reset() {
        let userInfo: [AnyHashable: Any] = ["type": "badge-reset"]

        XCTAssertTrue(PushNotificationSharedConstants.isKnownNotificationType(in: userInfo))
    }

    func test_isKnownNotificationType_returns_true_for_zendesk() {
        let userInfo: [AnyHashable: Any] = ["type": "zendesk"]

        XCTAssertTrue(PushNotificationSharedConstants.isKnownNotificationType(in: userInfo))
    }

    func test_isKnownNotificationType_returns_false_for_unknown_type() {
        let userInfo: [AnyHashable: Any] = ["type": "unknown_future_type", "blog": Int64(42)]

        XCTAssertFalse(PushNotificationSharedConstants.isKnownNotificationType(in: userInfo))
    }

    func test_isKnownNotificationType_returns_true_when_type_is_not_a_string() {
        let userInfo: [AnyHashable: Any] = ["type": 42]

        XCTAssertTrue(PushNotificationSharedConstants.isKnownNotificationType(in: userInfo),
                      "Non-string `type` is treated as absent, matching the local-notification fall-through.")
    }

    // MARK: - Parity with Note.Kind

    /// Drift tripwire: every `Note.Kind` case (except `.unknown`) must be in the shared known-types set,
    /// otherwise newly-added Note kinds would be silently discarded by the gate. See RSM-3048.
    func test_knownPushNotificationTypes_contains_every_NoteKind_raw_value_except_unknown() {
        let expected = Note.Kind.allCases
            .filter { $0 != .unknown }
            .map(\.rawValue)

        let missing = expected.filter { !PushNotificationSharedConstants.knownPushNotificationTypes.contains($0) }

        XCTAssertTrue(missing.isEmpty,
                      "Note.Kind raw values missing from PushNotificationSharedConstants.knownPushNotificationTypes: \(missing). " +
                      "Add them to the shared set or remove the corresponding Note.Kind case.")
    }
}
