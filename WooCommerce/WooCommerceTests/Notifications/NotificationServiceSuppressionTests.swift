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

    // MARK: - shouldSuppress

    func test_shouldSuppress_returns_true_when_site_is_registered_and_both_keys_present() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        XCTAssertTrue(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_site_is_not_registered() {
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_noteID_is_missing() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(42)]

        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_siteID_is_missing() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_userInfo_is_empty() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = [:]

        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_when_siteID_is_wrong_type() {
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": ["not", "an", "id"], "note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_tolerates_numeric_string_siteID() {
        // APNS may deliver `blog`/`note_id` as strings; parsing must match PushNotification.from.
        state.markSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": "42", "note_id": "1"]

        XCTAssertTrue(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_for_different_registered_site() {
        state.markSiteAsRegisteredForWooPNs(99)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_true_for_one_of_multiple_registered_sites() {
        state.markSiteAsRegisteredForWooPNs(10)
        state.markSiteAsRegisteredForWooPNs(20)
        state.markSiteAsRegisteredForWooPNs(30)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(20), "note_id": Int64(5)]

        XCTAssertTrue(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_returns_false_after_site_is_unregistered() {
        state.markSiteAsRegisteredForWooPNs(42)
        state.unmarkSiteAsRegisteredForWooPNs(42)

        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    // MARK: - shouldSuppress: symmetric feature-flag-driven behavior

    func test_shouldSuppress_when_FF_on_and_WPCom_push_for_registered_site_then_suppresses() {
        // Given
        state.selfDrivenPushEnabled = true
        state.markSiteAsRegisteredForWooPNs(42)
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        // Then
        XCTAssertTrue(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_when_FF_on_and_woo_push_then_does_not_suppress() {
        // Given
        state.selfDrivenPushEnabled = true
        state.markSiteAsRegisteredForWooPNs(42)
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "type": "store_order"]

        // Then
        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_when_FF_off_and_woo_push_for_torn_down_site_then_suppresses() {
        // Given — fell back to WPCom: FF off and the Woo registration has been cleared
        state.selfDrivenPushEnabled = false
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "type": "store_order"]

        // Then
        XCTAssertTrue(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_when_FF_off_and_store_stock_push_for_torn_down_site_then_suppresses() {
        // Given
        state.selfDrivenPushEnabled = false
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "type": "store_stock"]

        // Then
        XCTAssertTrue(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_when_FF_off_but_site_still_registered_then_does_not_suppress_woo() {
        // Given — WPCom re-enable still pending/failed, so the Woo state is not yet torn down
        state.selfDrivenPushEnabled = false
        state.markSiteAsRegisteredForWooPNs(42)
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "type": "store_order"]

        // Then — must NOT suppress, otherwise the merchant is blacked out during the fallback window
        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_when_FF_off_and_WPCom_push_then_does_not_suppress() {
        // Given
        state.selfDrivenPushEnabled = false
        state.markSiteAsRegisteredForWooPNs(42)
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "note_id": Int64(1)]

        // Then
        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_when_FF_unset_and_woo_push_then_does_not_suppress() {
        // Given — FF not yet resolved (nil): never hide a Woo-driven push
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "type": "store_order"]

        // Then
        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
    }

    func test_shouldSuppress_when_FF_off_and_non_woo_type_without_noteID_then_does_not_suppress() {
        // Given — a no-`note_id` push that is not a Woo store type (e.g. badge-reset)
        state.selfDrivenPushEnabled = false
        let userInfo: [AnyHashable: Any] = ["blog": Int64(42), "type": "badge-reset"]

        // Then
        XCTAssertFalse(state.shouldSuppress(userInfo: userInfo))
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

    func test_isKnownNotificationType_returns_true_for_store_stock() {
        let userInfo: [AnyHashable: Any] = ["type": "store_stock", "blog": Int64(42)]

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
