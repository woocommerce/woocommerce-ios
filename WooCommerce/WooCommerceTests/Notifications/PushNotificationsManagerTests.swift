import Combine
import Experiments
import XCTest
import Yosemite
@testable import WooCommerce


/// PushNotificationsManager Tests
///
@MainActor
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

    /// Mock: UserNotificationCenter
    ///
    private var userNotificationCenter: MockUserNotificationsCenterAdapter!

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Overridden Methods

    @MainActor
    override func setUp() {
        super.setUp()

        subscriptions = []

        application = MockApplicationAdapter()

        defaults = UserDefaults(suiteName: Sample.defaultSuiteName)
        defaults.removePersistentDomain(forName: Sample.defaultSuiteName)

        // Most of the test cases expect a nil site ID, otherwise the dispatched actions would not match.
        storesManager = MockStoresManager(sessionManager: .testingInstance)
        storesManager.sessionManager.setStoreId(nil)
        mockSynchronizeNotificationsAction()

        userNotificationCenter = MockUserNotificationsCenterAdapter()

        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration)
        }()
    }

    @MainActor
    override func tearDown() {
        manager.resetBadgeCountForAllStores {}
        manager = nil
        userNotificationCenter = nil
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

    /// Verifies that `handleNotification` dispatches a `synchronizeNotifications` Action, which, in turn, signals that there's
    /// new data available in the app, on success.
    ///
    func testHandleNotificationResultsInSynchronizeNotificationsActionWhichSignalsThatThereIsNewDataOnSuccessWhenAppStateIsBackground() async {
        // Given
        let payload = notificationPayload()

        // When
        application.applicationState = .background
        let result = await manager.handleRemoteNotificationInTheBackground(userInfo: payload)

        // Then
        XCTAssertEqual(result, .newData)

        guard case .synchronizeNotifications =
                storesManager.receivedActions.compactMap({ $0 as? NotificationAction }).first else {
            XCTFail()
            return
        }
    }


    /// Verifies that `handleNotification` dispatches a `synchronizeNotifications` Action, which, in turn, signals that there's
    /// NO New Data available in the app, on error.
    ///
    func testHandleNotificationResultsInSynchronizeNotificationsActionWhichSignalsThatThereIsNoNewDataOnErrorWhenAppStateIsBackground() async {
        // Given
        let payload = notificationPayload()
        mockSynchronizeNotificationsAction(error: NSError(domain: "", code: 0))

        // When
        application.applicationState = .background
        let result = await manager.handleRemoteNotificationInTheBackground(userInfo: payload)

        // Then
        XCTAssertEqual(result, .noData)

        guard case .synchronizeNotifications =
                storesManager.receivedActions.compactMap({ $0 as? NotificationAction }).first else {
            XCTFail()
            return
        }
    }

    /// Verifies that `handleNotification` opens the Notification Details for the newly received note, whenever the application
    /// state is inactive.
    ///
    func test_handleNotification_displays_details_for_the_new_notification_whenever_the_app_state_is_inactive() async throws {
        // Given
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration)
        }()
        let payload = notificationPayload(type: .storeOrder)
        let response = try XCTUnwrap(MockNotificationResponse(notificationUserInfo: payload))

        // When
        application.applicationState = .inactive
        await manager.handleUserResponseToNotification(response)

        // Then
        XCTAssertEqual(application.presentDetailsNoteIDs.first, 1234)
    }

    /// Verifies that `handleNotification` displays an InApp Notification with title and message whenever the app is in active state and both title
    /// and message are present in the payload.
    ///
    func test_handleNotification_displays_inApp_notice_with_title_and_message_when_app_state_is_active() async throws {
        // Given
        let payload = notificationPayload(title: Sample.defaultTitle,
                                          subtitle: Sample.defaultSubtitle,
                                          message: Sample.defaultMessage)
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration)
        }()

        // When
        application.applicationState = .active
        let notification = try XCTUnwrap(MockNotification(userInfo: payload))
        _ = await manager.handleNotificationInTheForeground(notification)

        // Then
        XCTAssertEqual(application.presentInAppMessages.first?.title, Sample.defaultTitle)
        XCTAssertEqual(application.presentInAppMessages.first?.subtitle, Sample.defaultSubtitle)
        XCTAssertEqual(application.presentInAppMessages.first?.message, Sample.defaultMessage)
    }

    /// Verifies that `handleNotification` displays an InApp Notification with title only whenever the app is in active state and only title
    /// is present in the payload.
    ///
    func test_handleNotification_displays_inApp_notice_with_title_only_when_app_state_is_active_and_only_title_in_payload() async throws {
        // Given
        let payload = notificationPayload(title: Sample.defaultTitle, message: nil)
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration)
        }()

        // When
        application.applicationState = .active
        let notification = try XCTUnwrap(MockNotification(userInfo: payload))
        _ = await manager.handleNotificationInTheForeground(notification)

        // Then
        XCTAssertEqual(application.presentInAppMessages.first?.title, Sample.defaultTitle)
        XCTAssertNil(application.presentInAppMessages.first?.subtitle)
        XCTAssertNil(application.presentInAppMessages.first?.message)
    }

    // MARK: - Foreground Notification Observable

    func test_it_emits_foreground_notifications_when_it_receives_a_notification_while_app_is_active() async throws {
        // Given
        application.applicationState = .active

        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration)
        }()

        var emittedNotifications = [PushNotification]()
        manager.foregroundNotifications.sink { notification in
            emittedNotifications.append(notification)
        }.store(in: &subscriptions)

        let userinfo = notificationPayload(noteID: 9_981,
                                           type: .storeOrder,
                                           title: Sample.defaultTitle,
                                           subtitle: Sample.defaultSubtitle,
                                           message: Sample.defaultMessage)

        // When
        let notification = try XCTUnwrap(MockNotification(userInfo: userinfo))
        _ = await manager.handleNotificationInTheForeground(notification)

        // Then
        XCTAssertEqual(emittedNotifications.count, 1)

        let emittedNotification = try XCTUnwrap(emittedNotifications.first)
        XCTAssertEqual(emittedNotification.kind, .storeOrder)
        XCTAssertEqual(emittedNotification.noteID, 9_981)
        XCTAssertEqual(emittedNotification.title, Sample.defaultTitle)
        XCTAssertEqual(emittedNotification.subtitle, Sample.defaultSubtitle)
        XCTAssertEqual(emittedNotification.message, Sample.defaultMessage)
    }

    func test_it_does_not_emit_foreground_notifications_when_it_receives_a_notification_while_app_is_not_active() async {
        // Given
        application.applicationState = .background

        var emittedNotifications = [PushNotification]()
        _ = manager.foregroundNotifications.sink { notification in
            emittedNotifications.append(notification)
        }

        let userinfo = notificationPayload(noteID: 9_981, type: .storeOrder)

        // When
        _ = await manager.handleRemoteNotificationInTheBackground(userInfo: userinfo)

        // Then
        XCTAssertTrue(emittedNotifications.isEmpty)
    }

    func test_it_emits_inactive_notifications_with_title_only_given_a_notification_while_the_app_is_inactive_and_only_title_in_payload() async throws {
        // Given
        application.applicationState = .inactive
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration)
        }()

        var emittedNotifications = [PushNotification]()
        manager.inactiveNotifications.sink { notification in
            emittedNotifications.append(notification)
        }.store(in: &subscriptions)

        let userinfo = notificationPayload(noteID: 9_981, type: .storeOrder, title: Sample.defaultTitle)
        let response = try XCTUnwrap(MockNotificationResponse(notificationUserInfo: userinfo))

        // When
        _ = await manager.handleUserResponseToNotification(response)

        // Then
        XCTAssertEqual(emittedNotifications.count, 1)

        let emittedNotification = try XCTUnwrap(emittedNotifications.first)
        XCTAssertEqual(emittedNotification.kind, .storeOrder)
        XCTAssertEqual(emittedNotification.noteID, 9_981)
        XCTAssertEqual(emittedNotification.title, Sample.defaultTitle)
        XCTAssertNil(emittedNotification.subtitle)
        XCTAssertNil(emittedNotification.message)
    }

    // MARK: - Background Notification Observable

    func test_it_emits_background_notifications_when_it_receives_a_notification_while_app_is_in_the_background() async throws {
        // Given
        application.applicationState = .background

        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)
            return PushNotificationsManager(configuration: configuration)
        }()

        var emittedNotifications = [PushNotification]()
        manager.backgroundNotifications.sink { notification in
            emittedNotifications.append(notification)
        }.store(in: &subscriptions)

        let userinfo = notificationPayload(noteID: 9_981,
                                           type: .storeOrder,
                                           siteID: 606,
                                           title: Sample.defaultTitle,
                                           subtitle: Sample.defaultSubtitle,
                                           message: Sample.defaultMessage)

        // When
        _ = await manager.handleRemoteNotificationInTheBackground(userInfo: userinfo)

        // Then
        XCTAssertEqual(emittedNotifications.count, 1)

        let emittedNotification = try XCTUnwrap(emittedNotifications.first)
        XCTAssertEqual(emittedNotification.kind, .storeOrder)
        XCTAssertEqual(emittedNotification.noteID, 9_981)
        XCTAssertEqual(emittedNotification.siteID, 606)
        XCTAssertEqual(emittedNotification.title, Sample.defaultTitle)
        XCTAssertEqual(emittedNotification.subtitle, Sample.defaultSubtitle)
        XCTAssertEqual(emittedNotification.message, Sample.defaultMessage)
    }

    // MARK: - App Badge Number

    /// Verifies that `handleNotification` updates app badge number to 1 when the notification is from the same site.
    func test_receiving_notification_from_the_same_site_updates_app_badge_number() async {
        // Arrange
        application.applicationState = .background
        // A site ID and the default stores are required to update the application badge number.
        let stores = DefaultStoresManager.testingInstance
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: stores,
                                                               userNotificationsCenter: self.userNotificationCenter)
            return PushNotificationsManager(configuration: configuration)
        }()
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        let siteID = Int64(123)
        stores.updateDefaultStore(storeID: siteID)
        XCTAssertEqual(application.applicationIconBadgeNumber, .min)

        // Action
        let userInfo = notificationPayload(badgeCount: 10, type: .comment, siteID: siteID)
        _ = await manager.handleRemoteNotificationInTheBackground(userInfo: userInfo)

        // Assert
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.hasUnreadPushNotifications)
        XCTAssertFalse(userNotificationCenter.removeAllNotificationsWasCalled)
    }

    /// Verifies that `handleNotification` twice does not change app badge number from 1 when both notifications are from the same site.
    func test_receiving_two_notifications_from_the_same_site_does_not_change_app_badge_number() async {
        // Arrange
        application.applicationState = .background
        // A site ID and the default stores are required to update the application badge number.
        let stores = DefaultStoresManager.testingInstance
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: stores,
                                                               userNotificationsCenter: self.userNotificationCenter)
            return PushNotificationsManager(configuration: configuration)
        }()
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        let siteID = Int64(123)
        stores.updateDefaultStore(storeID: siteID)
        XCTAssertEqual(application.applicationIconBadgeNumber, .min)

        // Action
        let userInfoForTheFirstNotification = notificationPayload(badgeCount: 10, type: .comment, siteID: siteID)
        let userInfoForTheSecondNotification = notificationPayload(badgeCount: 2, type: .storeOrder, siteID: siteID)
        _ = await manager.handleRemoteNotificationInTheBackground(userInfo: userInfoForTheFirstNotification)
        _ = await manager.handleRemoteNotificationInTheBackground(userInfo: userInfoForTheSecondNotification)

        // Assert
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.hasUnreadPushNotifications)
        XCTAssertFalse(userNotificationCenter.removeAllNotificationsWasCalled)
    }

    /// Verifies that `handleNotification` clears app badge number without clearing push notifications when the notification is from a different site.
    func test_receiving_notification_from_a_different_site_clears_app_badge_number_only() async {
        // Arrange
        application.applicationState = .background
        // A site ID and the default stores are required to update the application badge number.
        let stores = DefaultStoresManager.testingInstance
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: stores,
                                                               userNotificationsCenter: self.userNotificationCenter)
            return PushNotificationsManager(configuration: configuration)
        }()
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        stores.updateDefaultStore(storeID: 123)
        XCTAssertEqual(application.applicationIconBadgeNumber, .min)

        // Action
        let userInfo = notificationPayload(badgeCount: 10, type: .comment, siteID: 556)
        _ = await manager.handleRemoteNotificationInTheBackground(userInfo: userInfo)

        // Assert
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.clearsBadgeOnly)
        XCTAssertFalse(userNotificationCenter.removeAllNotificationsWasCalled)
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
        XCTAssertEqual(application.applicationIconBadgeNumber, AppIconBadgeNumber.clearsBadgeAndPotentiallyAllPushNotifications)
        XCTAssertTrue(userNotificationCenter.removeAllNotificationsWasCalled)
    }
}


// MARK: - Private Methods
//
private extension PushNotificationsManagerTests {

    /// Returns a Sample Notification Payload
    ///
    func notificationPayload(badgeCount: Int = 0,
                             noteID: Int64 = 1234,
                             type: Note.Kind = .comment,
                             siteID: Int64 = 134,
                             title: String = Sample.defaultTitle,
                             subtitle: String? = nil,
                             message: String? = nil) -> [String: Any] {
        [
            "aps": [
                "badge": badgeCount,
                "alert": [
                    "title": title,
                    "subtitle": subtitle,
                    "body": message
                ]
            ] as [String: Any],
            "note_id": noteID,
            "type": type.rawValue,
            "blog": siteID
        ]
    }

    func mockSynchronizeNotificationsAction(error: Error? = nil) {
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case .synchronizeNotifications(let completion) = action {
                completion(error)
            }
        }
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

    /// Sample Title
    ///
    static let defaultTitle = "You have a new order! 🎊"

    /// Sample Subtitle
    ///
    static let defaultSubtitle = "Your favorite shop"

    /// Sample Message
    ///
    static let defaultMessage = "Loren Ipsum Expectom patronum wingardium leviousm"
}
