import XCTest
import UserNotifications
import Yosemite
@testable import WooCommerce


/// PushNotificationsManager Tests
///
class PushNotificationsManagerTests: XCTestCase {

    /// PushNotifications Manager
    ///
    private lazy var manager: PushNotificationsManager = {
        let configuration = PushNotificationsConfiguration(application: self.application,
                                                           defaults: self.defaults,
                                                           storesManager: self.storesManager,
                                                           notificationsDelegate: self.userNotificationCenter)

        return PushNotificationsManager(configuration: configuration)
    }()

    /// Mockup: UIApplication
    ///
    private var application = MockupApplication()

    /// UserDefaults: Testing Suite
    ///
    private var defaults = UserDefaults(suiteName: Sample.defaultSuiteName)!

    /// Mockup: Stores Manager
    ///
    private var storesManager = MockupStoresManager(sessionManager: .testingInstance)

    /// Mockup: UserNotificationCenter
    ///
    private var userNotificationCenter = MockupUserNotificationsCenterAdapter()



    // MARK: - Overridden Methods

    override func setUp() {
        defaults.removePersistentDomain(forName: Sample.defaultSuiteName)
        application.reset()
        storesManager.reset()
        userNotificationCenter.reset()
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


    /// Verifies that `unregisterForRemoteNotifications` does not dispatch any action, whenever the DeviceID is unknown.
    ///
    func testUnregisterForRemoteNotificationsDoesNothingWhenThereIsNoDeviceIdStored() {
        XCTAssert(storesManager.receivedActions.isEmpty)
        manager.unregisterForRemoteNotifications()
        XCTAssert(storesManager.receivedActions.isEmpty)
    }

    /// Verifies that `unregisterForRemoteNotifications` does dispatch `.unregisterDevice` Action, whenever the
    /// deviceID is known.
    ///
    func testUnregisterForRemoteNotificationsEffectivelyDispatchesUnregisterDeviceAction() {
        defaults.set(Sample.deviceID, forKey: .deviceID)
        manager.unregisterForRemoteNotifications()

        guard case let .unregisterDevice(deviceID, _) = storesManager.receivedActions.first as! NotificationAction else {
            XCTFail()
            return
        }

        XCTAssertEqual(deviceID, Sample.deviceID)
    }


    /// Verifies that `unregisterForRemoteNotifications` does nuke the DeviceID and DeviceToken, whenever the `unregisterDevice`
    /// Action is successful.
    ///
    func testUnregisterForRemoteNotificationsEffectivelyNukesDeviceIdentifierAndTokenOnSuccess() {
        defaults.set(Sample.deviceID, forKey: .deviceID)
        defaults.set(Sample.deviceToken, forKey: .deviceToken)

        manager.unregisterForRemoteNotifications()

        guard case let .unregisterDevice(_, onCompletion) = storesManager.receivedActions.first as! NotificationAction else {
            XCTFail()
            return
        }

        onCompletion(nil)

        XCTAssertFalse(defaults.containsObject(forKey: .deviceID))
        XCTAssertFalse(defaults.containsObject(forKey: .deviceToken))
    }


    /// Verifies that `registerDevice` effectively dispatches a `registerDevice` Action.
    ///
    func testRegisterForRemoteNotificationsDispatchesRegisterDeviceAction() {
        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            XCTFail()
            return
        }

        manager.registerDeviceToken(with: tokenAsData, defaultStoreID: Sample.defaultStoreID)

        guard case let .registerDevice(_, _, _, storeID, _) = storesManager.receivedActions.first as! NotificationAction else {
            XCTFail()
            return
        }

        XCTAssertEqual(storeID, Sample.defaultStoreID)
    }


    /// Verifies that `registerDeviceToken` effectively stores the Device Token.
    ///
    func testRegisterForRemoteNotificationsStoresDeviceTokenInUserDefaults() {
        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            XCTFail()
            return
        }

        XCTAssertFalse(defaults.containsObject(forKey: .deviceToken))
        manager.registerDeviceToken(with: tokenAsData, defaultStoreID: Sample.defaultStoreID)
        XCTAssertTrue(defaults.containsObject(forKey: .deviceToken))
    }


    /// Verifies that `registrationDidFail` enqueues a `unregisterDevice` NotificationAction.
    ///
    func testRegistrationDidFailDispatchesUnregisterDeviceAction() {
        defaults.set(Sample.deviceID, forKey: .deviceID)

        manager.registrationDidFail(with: SampleError.first)

        XCTAssertEqual(storesManager.receivedActions.count, 1)
        let action = storesManager.receivedActions.first as! NotificationAction

        switch action {
        case .unregisterDevice:
            break
        default:
            XCTFail()
        }
    }


    /// Verifies that `handleNotification` effectively updates the App's Badge Number.
    ///
    func testHandleNotificationUpdatesApplicationsBadgeNumber() {
        let updatedBadgeNumber = 10
        let userInfo = notificationPayload(badgeCount: updatedBadgeNumber)

        XCTAssertEqual(application.applicationIconBadgeNumber, Int.min)

        manager.handleNotification(userInfo) { _ in }
        XCTAssertEqual(application.applicationIconBadgeNumber, updatedBadgeNumber)
    }


    /// Verifies that `handleNotification` dispatches a `synchronizeNotifications` Action, which, in turn, signals that there's
    /// new data available in the app, on success.
    ///
    func testHandleNotificationResultsInSynchronizeNotificationsActionWhichSignalsThatThereIsNewDataOnSuccess() {
        let payload = notificationPayload()
        var handleNotificationCallbackWasExecuted = false

        application.applicationState = .background
        manager.handleNotification(payload) { result in
            XCTAssertEqual(result, .newData)
            handleNotificationCallbackWasExecuted = true
        }

        guard case let .synchronizeNotifications(onCompletion) = storesManager.receivedActions.first as! NotificationAction else {
            XCTFail()
            return
        }

        // Simulate Action Execution: This is actually a synchronous OP. No need to wait!
        onCompletion(nil)
        XCTAssertTrue(handleNotificationCallbackWasExecuted)
    }


    /// Verifies that `handleNotification` dispatches a `synchronizeNotifications` Action, which, in turn, signals that there's
    /// NO New Data available in the app, on error.
    ///
    func testHandleNotificationResultsInSynchronizeNotificationsActionWhichSignalsThatThereIsNoNewDataOnError() {
        let payload = notificationPayload()
        var handleNotificationCallbackWasExecuted = false

        application.applicationState = .background
        manager.handleNotification(payload) { result in
            XCTAssertEqual(result, .noData)
            handleNotificationCallbackWasExecuted = true
        }

        guard case let .synchronizeNotifications(onCompletion) = storesManager.receivedActions.first as! NotificationAction else {
            XCTFail()
            return
        }

        // Simulate Action Execution: This is actually a synchronous OP. No need to wait!
        onCompletion(SampleError.first)
        XCTAssertTrue(handleNotificationCallbackWasExecuted)
    }
}


// MARK: - Private Methods
//
private extension PushNotificationsManagerTests {

    /// Returns a Sample Notification Payload
    ///
    func notificationPayload(badgeCount: Int = 0, noteID: Int = 1234) -> [String: Any] {
        return [
            "aps.badge": badgeCount,
            "note_id": noteID
        ]
    }
}


// MARK: - Testing Constants
//
private struct Sample {

    /// Sample DeviceID
    ///
    static let deviceID = "1234"

    /// Sample DeviceToken
    ///
    static let deviceToken = "4fa963db2cfc824b0d67740ed2b1c0b472cce8eafcb82184905361eb88be55b9"

    /// Sample StoreID
    ///
    static let defaultStoreID = 9999

    /// UserDefaults Suite Name
    ///
    static let defaultSuiteName = "PushNotificationsTests"
}
