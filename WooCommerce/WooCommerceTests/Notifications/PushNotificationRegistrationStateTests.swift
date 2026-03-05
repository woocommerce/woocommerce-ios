import XCTest
@testable import WooCommerce

final class PushNotificationRegistrationStateTests: XCTestCase {
    private var defaults: UserDefaults!
    private var state: PushNotificationRegistrationState!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "PushNotificationRegistrationStateTests")
        defaults.removePersistentDomain(forName: "PushNotificationRegistrationStateTests")
        state = PushNotificationRegistrationState(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "PushNotificationRegistrationStateTests")
        defaults = nil
        state = nil
        super.tearDown()
    }

    func test_siteIDsRegisteredForWooPNs_returns_empty_when_missing() {
        XCTAssertEqual(state.siteIDsRegisteredForWooPNs, [])
    }

    func test_hasStoredSiteIDsRegisteredForWooPNs_is_false_when_missing() {
        XCTAssertFalse(state.hasStoredSiteIDsRegisteredForWooPNs)
    }

    func test_siteIDsRegisteredForWooPNs_parses_ids_from_string() {
        defaults.set("1,2,3", forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications)
        state = PushNotificationRegistrationState(defaults: defaults)

        XCTAssertEqual(state.siteIDsRegisteredForWooPNs, [1, 2, 3])
    }

    func test_hasStoredSiteIDsRegisteredForWooPNs_is_true_when_value_exists() {
        defaults.set("", forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications)
        state = PushNotificationRegistrationState(defaults: defaults)

        XCTAssertTrue(state.hasStoredSiteIDsRegisteredForWooPNs)
    }

    func test_markSiteAsRegisteredForWooPNs_persists_string_value() {
        state.markSiteAsRegisteredForWooPNs(5)
        state.markSiteAsRegisteredForWooPNs(9)

        XCTAssertEqual(defaults.string(forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications), "5,9")
    }

    func test_markSiteAsRegisteredForWooPNs_adds_site_id_once() {
        state.markSiteAsRegisteredForWooPNs(4)
        state.markSiteAsRegisteredForWooPNs(4)

        XCTAssertEqual(state.siteIDsRegisteredForWooPNs, [4])
        XCTAssertTrue(state.hasStoredSiteIDsRegisteredForWooPNs)
    }

    func test_unmarkSiteAsRegisteredForWooPNs_removes_site_id() {
        defaults.set("1,2", forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications)
        state = PushNotificationRegistrationState(defaults: defaults)

        state.unmarkSiteAsRegisteredForWooPNs(1)

        XCTAssertEqual(state.siteIDsRegisteredForWooPNs, [2])
    }

    func test_unmarkSiteAsRegisteredForWooPNs_initializes_key_when_missing() {
        XCTAssertNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications))

        state.unmarkSiteAsRegisteredForWooPNs(123)

        XCTAssertNotNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications))
        XCTAssertEqual(defaults.string(forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications), "")
    }

    func test_applyNewDeviceToken_persists_device_token() {
        state.applyNewDeviceToken("sample-token")

        XCTAssertEqual(state.deviceToken, "sample-token")
        XCTAssertEqual(defaults.string(forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken), "sample-token")
    }
}
