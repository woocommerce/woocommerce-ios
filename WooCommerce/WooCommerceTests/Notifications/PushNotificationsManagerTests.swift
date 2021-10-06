import XCTest
import UserNotifications
import Yosemite
@testable import WooCommerce


/// PushNotificationsManager Tests
///
final class PushNotificationsManagerTests: XCTestCase {

    /// PushNotifications Manager
    ///
    private var manager: PushNotificationsManager!

    /// Mock: UIApplication
    ///
    private var application: MockApplicationAdapter!

    /// UserDefaults: Testing Suite
    ///
    private var defaults: UserDefaults!

    /// Mock: Stores Manager
    ///
    private var storesManager: MockStoresManager!

    /// Mock: Support Manager
    ///
    private var supportManager: MockSupportManager!

    /// Mock: UserNotificationCenter
    ///
    private var userNotificationCenter: MockUserNotificationsCenterAdapter!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        application = MockApplicationAdapter()

        defaults = UserDefaults(suiteName: Sample.defaultSuiteName)
        defaults.removePersistentDomain(forName: Sample.defaultSuiteName)

        // Most of the test cases expect a nil site ID, otherwise the dispatched actions would not match.
        storesManager = MockStoresManager(sessionManager: .testingInstance)
        storesManager.sessionManager.setStoreId(nil)

        supportManager = MockSupportManager()
        userNotificationCenter = MockUserNotificationsCenterAdapter()

        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               supportManager: self.supportManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration)
        }()
    }

    override func tearDown() {
        manager.resetBadgeCountForAllStores {}
        manager = nil
        userNotificationCenter = nil
        supportManager = nil
        storesManager = nil

        defaults.removePersistentDomain(forName: Sample.defaultSuiteName)
        defaults = nil

        application = nil
        super.tearDown()
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


    /// Verifies that `unregisterForRemoteNotifications` relays the Unregister call to the Support Manager.
    ///
    func testUnregisterForRemoteNotificationsRelaysUnregisterCallToSupportManager() {
        XCTAssertFalse(supportManager.unregisterWasCalled)
        manager.unregisterForRemoteNotifications()
        XCTAssertTrue(supportManager.unregisterWasCalled)
    }


    /// Verifies that `registerDevice` effectively dispatches a `registerDevice` Action.
    ///
    func testRegisterForRemoteNotificationsDispatchesRegisterDeviceAction() {
        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            XCTFail()
            return
        }

        manager.registerDeviceToken(with: tokenAsData, defaultStoreID: Sample.defaultStoreID)

        guard case let .registerDevice(_, _, _, storeID, _, _) = storesManager.receivedActions.first as! NotificationAction else {
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


    /// Verifies that `registerDevice` effectively relays the register call to the Support Manager.
    ///
    func testRegisterForRemoteNotificationsRelaysRegisterCallToSupportManager() {
        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            XCTFail()
            return
        }

        XCTAssert(supportManager.registeredDeviceTokens.isEmpty)
        manager.registerDeviceToken(with: tokenAsData, defaultStoreID: Sample.defaultStoreID)
        XCTAssertEqual(supportManager.registeredDeviceTokens.first, tokenAsData.hexString)
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

    /// Verifies that `handleNotification` dispatches a `synchronizeNotifications` Action, which, in turn, signals that there's
    /// new data available in the app, on success.
    ///
    func testHandleNotificationResultsInSynchronizeNotificationsActionWhichSignalsThatThereIsNewDataOnSuccessWhenAppStateIsBackground() {
        let payload = notificationPayload()
        var handleNotificationCallbackWasExecuted = false

        application.applicationState = .background
        manager.handleNotification(payload, onBadgeUpdateCompletion: {}) { result in
            XCTAssertEqual(result, .newData)
            handleNotificationCallbackWasExecuted = true
        }

        guard case let .synchronizeNotifications(onCompletion) =
                storesManager.receivedActions.compactMap({ $0 as? NotificationAction }).first else {
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
    func testHandleNotificationResultsInSynchronizeNotificationsActionWhichSignalsThatThereIsNoNewDataOnErrorWhenAppStateIsBackground() {
        let payload = notificationPayload()
        var handleNotificationCallbackWasExecuted = false

        application.applicationState = .background
        manager.handleNotification(payload, onBadgeUpdateCompletion: {}) { result in
            XCTAssertEqual(result, .noData)
            handleNotificationCallbackWasExecuted = true
        }

        guard case let .synchronizeNotifications(onCompletion) =
                storesManager.receivedActions.compactMap({ $0 as? NotificationAction }).first else {
            XCTFail()
            return
        }

        // Simulate Action Execution: This is actually a synchronous OP. No need to wait!
        onCompletion(SampleError.first)
        XCTAssertTrue(handleNotificationCallbackWasExecuted)
    }


    /// Verifies that `handleNotification` opens the Notification Details for the newly received note, whenever the application
    /// state is inactive.
    ///
    func testHandleNotificationDisplaysDetailsForTheNewNotificationWheneverTheAppStateIsInactive() {
        let payload = notificationPayload(type: .storeOrder)
        var handleNotificationCallbackWasExecuted = false

        application.applicationState = .inactive
        manager.handleNotification(payload, onBadgeUpdateCompletion: {}) { result in
            XCTAssertEqual(result, .newData)
            handleNotificationCallbackWasExecuted = true
        }

        XCTAssertEqual(application.presentDetailsNoteIDs.first, 1234)
        XCTAssertTrue(handleNotificationCallbackWasExecuted)
    }


    /// Verifies that `handleNotification` displays an InApp Notification whenever the app is in active state.
    ///
    func testHandleNotificationDisplaysInAppNotificationWheneverTheAppStateIsActive() {
        let payload = notificationPayload()

        application.applicationState = .active
        manager.handleNotification(payload, onBadgeUpdateCompletion: {}) { _ in
            // NO-OP
        }

        XCTAssertEqual(application.presentInAppMessages.first, Sample.defaultMessage)
    }

    // MARK: - Foreground Notification Observable

    func testItEmitsForegroundNotificationsWhenItReceivesANotificationWhileAppIsActive() {
        // Given
        application.applicationState = .active

        var emittedNotifications = [PushNotification]()
        _ = manager.foregroundNotifications.subscribe { notification in
            emittedNotifications.append(notification)
        }

        let userinfo = notificationPayload(noteID: 9_981, type: .storeOrder)

        // When
        manager.handleNotification(userinfo, onBadgeUpdateCompletion: {}) { _ in
            // noop
        }

        // Then
        XCTAssertEqual(emittedNotifications.count, 1)

        let emittedNotification = emittedNotifications.first!
        XCTAssertEqual(emittedNotification.kind, .storeOrder)
        XCTAssertEqual(emittedNotification.noteID, 9_981)
        XCTAssertEqual(emittedNotification.message, Sample.defaultMessage)
    }

    func testItDoesNotEmitForegroundNotificationsWhenItReceivesANotificationWhileAppIsNotActive() {
        // Given
        application.applicationState = .background

        var emittedNotifications = [PushNotification]()
        _ = manager.foregroundNotifications.subscribe { notification in
            emittedNotifications.append(notification)
        }

        let userinfo = notificationPayload(noteID: 9_981, type: .storeOrder)

        // When
        manager.handleNotification(userinfo, onBadgeUpdateCompletion: {}) { _ in
            // noop
        }

        // Then
        XCTAssertTrue(emittedNotifications.isEmpty)
    }

    func testItEmitsInactiveNotificationsWhenItReceivesANotificationWhileTheAppIsNotActive() throws {
        // Given
        application.applicationState = .inactive

        var emittedNotifications = [PushNotification]()
        _ = manager.inactiveNotifications.subscribe { notification in
            emittedNotifications.append(notification)
        }

        let userinfo = notificationPayload(noteID: 9_981, type: .storeOrder)

        // When
        manager.handleNotification(userinfo, onBadgeUpdateCompletion: {}) { _ in
            // noop
        }

        // Then
        XCTAssertEqual(emittedNotifications.count, 1)

        let emittedNotification = try XCTUnwrap(emittedNotifications.first)
        XCTAssertEqual(emittedNotification.kind, .storeOrder)
        XCTAssertEqual(emittedNotification.noteID, 9_981)
        XCTAssertEqual(emittedNotification.message, Sample.defaultMessage)
    }

    // MARK: - App Badge Number

    /// Verifies that `handleNotification` updates app badge number to 1 when the notification is from the same site.
    func test_receiving_notification_from_the_same_site_updates_app_badge_number() {
        // Arrange
        // A site ID and the default stores are required to update the application badge number.
        let stores = DefaultStoresManager.testingInstance
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: stores,
                                                               supportManager: self.supportManager,
                                                               userNotificationsCenter: self.userNotificationCenter)
            return PushNotificationsManager(configuration: configuration)
        }()
        ServiceLocator.setPushNotesManager(manager)
        stores.authenticate(credentials: SessionSettings.credentials)
        let siteID = Int64(123)
        stores.updateDefaultStore(storeID: siteID)
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.clearsBadgeOnly)

        // Action
        let userInfo = notificationPayload(badgeCount: 10, type: .comment, siteID: siteID)
        waitFor { promise in
            self.manager.handleNotification(userInfo, onBadgeUpdateCompletion: {
                promise(())
            }) { _ in }
        }

        // Assert
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.hasUnreadPushNotifications)
    }

    /// Verifies that `handleNotification` does not update app badge number when the notification is from a different site.
    func test_receiving_notification_from_a_different_site_does_not_change_app_badge_number() {
        // Arrange
        // A site ID and the default stores are required to update the application badge number.
        let stores = DefaultStoresManager.testingInstance
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: stores,
                                                               supportManager: self.supportManager,
                                                               userNotificationsCenter: self.userNotificationCenter)
            return PushNotificationsManager(configuration: configuration)
        }()
        ServiceLocator.setPushNotesManager(manager)
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.updateDefaultStore(storeID: 123)
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.clearsBadgeOnly)

        // Action
        let userInfo = notificationPayload(badgeCount: 10, type: .comment, siteID: 556)
        waitFor { promise in
            self.manager.handleNotification(userInfo, onBadgeUpdateCompletion: {
                promise(())
            }) { _ in }
        }

        // Assert
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.clearsBadgeOnly)
    }

    /// Verifies that `resetBadgeCountForAllStores` clears app badge number and push notifications.
    func test_resetBadgeCountForAllStores_clears_app_badge_number_and_push_notifications() {
        // Arrange
        // The default stores are required to update the application badge number.
        let stores = DefaultStoresManager.testingInstance
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: stores,
                                                               supportManager: self.supportManager,
                                                               userNotificationsCenter: self.userNotificationCenter)
            return PushNotificationsManager(configuration: configuration)
        }()
        application.applicationIconBadgeNumber = 90

        // Action
        waitFor { promise in
            self.manager.resetBadgeCountForAllStores {
                promise(())
            }
        }

        // Assert
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.clearsBadgeAndAllPushNotifications)
    }
}


// MARK: - Private Methods
//
private extension PushNotificationsManagerTests {

    /// Returns a Sample Notification Payload
    ///
    func notificationPayload(badgeCount: Int = 0, noteID: Int64 = 1234, type: Note.Kind = .comment, siteID: Int64 = 134) -> [String: Any] {
        return [
            "aps": [
                "badge": badgeCount,
                "alert": Sample.defaultMessage
            ],
            "note_id": noteID,
            "type": type.rawValue,
            "blog": siteID
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
    static let defaultStoreID: Int64 = 9999

    /// UserDefaults Suite Name
    ///
    static let defaultSuiteName = "PushNotificationsTests"

    /// Sample Message
    ///
    static let defaultMessage = "Loren Ipsum Expectom patronum wingardium leviousm"
}
