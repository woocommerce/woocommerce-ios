import XCTest
import UserNotifications
@testable import WooCommerce


/// PushNotificationsManager Tests
///
class PushNotificationsManagerTests: XCTestCase {

    /// Testing UserDefaults
    ///
    private var defaults = UserDefaults(suiteName: "PushNotificationsTests")!

    /// Testing ApplicationWrapper
    ///
    private var application: MockupApplication!

    /// Testing UserNotificationCenterWrapper
    ///
    private var userNotificationCenter: MockupUserNotificationCenter!

    /// PushNotificationsManager Instance
    ///
    private var manager: PushNotificationsManager!


    // MARK: - Overridden Methods

    override func setUp() {
        application = MockupApplication()
        userNotificationCenter = MockupUserNotificationCenter()
        let configuration = PushNotificationsConfiguration(defaults: defaults,
                                                           application: application,
                                                           userNotificationCenter: userNotificationCenter)
        manager = PushNotificationsManager(configuration: configuration)
    }


    /// Verifies that the PushNotificationsManager calls `registerForRemoteNotifications` in the UIApplication's Wrapper.
    ///
    func testRegisterForRemoteNotificationRelaysRegistrationMessageToUIKitApplication() {
        XCTAssertFalse(application.registerWasCalled)
        manager.registerForRemoteNotifications()
        XCTAssertTrue(application.registerWasCalled)
    }


    /// Verifies that `ensureAuthorizationIsRequested` effectively requests Push Notes Auth via UNUserNotificationsCenter,
    /// whenever the initial status is `.notDetermined`. This specific tests verifies the `Non Authorized` flow.
    ///
    func testEnsureAuthorizationIsRequestedEffectivelyRequestsAuthorizationWheneverInitialStatusIsUndeterminedAndUltimatelyFails() {
        userNotificationCenter.authorizationStatus = .notDetermined
        userNotificationCenter.requestAuthorizationIsSuccessful = false

        manager.ensureAuthorizationIsRequested { authorized in
            XCTAssertFalse(authorized)
        }
    }


    /// Verifies that `ensureAuthorizationIsRequested` effectively requests Push Notes Auth via UNUserNotificationsCenter,
    /// whenever the initial status is `.notDetermined`. This specific tests verifies the `Authorized` flow.
    ///
    func testEnsureAuthorizationIsRequestedEffectivelyRequestsAuthorizationWheneverInitialStatusIsUndeterminedAndUltimatelySucceeds() {
        userNotificationCenter.authorizationStatus = .notDetermined
        userNotificationCenter.requestAuthorizationIsSuccessful = true

        manager.ensureAuthorizationIsRequested { authorized in
            XCTAssertTrue(authorized)
        }
    }


    /// Verifies that whenever the Push Notifications Authorization status is anything other than `notDetermined`, we will
    /// *not* proceed to request auth, yet again.
    ///
    func testEnsureAuthorizationIsRequestedDoesntRequestAuthorizationOnceTheInitialStatusIsDetermined() {
        let determinedStatuses: [UNAuthorizationStatus] = [.authorized, .denied]

        for determinedStatus in determinedStatuses {
            userNotificationCenter.authorizationStatus = determinedStatus
            manager.ensureAuthorizationIsRequested()
            XCTAssertFalse(userNotificationCenter.requestAuthorizationWasCalled)
        }
    }


    /// Verifies that `handleNotification` effectively updates the App's Badge Number.
    ///
    func testHandleNotificationUpdatesApplicationsBadgeNumber() {
        let updatedBadgeNumber = 10
        let userInfo: [String: Any] = [
            "aps.badge": updatedBadgeNumber,
            "type": "badge-reset"
        ]

        XCTAssertEqual(application.applicationIconBadgeNumber, Int.min)

        manager.handleNotification(userInfo) { _ in }
        XCTAssertEqual(application.applicationIconBadgeNumber, updatedBadgeNumber)
    }
}
