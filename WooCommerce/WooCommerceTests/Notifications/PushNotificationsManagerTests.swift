import Combine
import Experiments
import XCTest
import Yosemite
import YosemiteTestHelpers
import enum NetworkingCore.NetworkError
import protocol WooFoundation.Analytics
@testable import WooCommerce
import class Storage.Site


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

    /// Mock: PushNotificationBackgroundSynchronizerFactory
    ///
    private var backgroundSynchronizerFactory: MockPushNotificationBackgroundSynchronizerFactory!

    /// Mock: Storage Manager
    ///
    private var storageManager: MockStorageManager!

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
        backgroundSynchronizerFactory = MockPushNotificationBackgroundSynchronizerFactory()
        storageManager = MockStorageManager()

        manager = makeManager()
    }

    @MainActor
    override func tearDown() {
        manager.resetBadgeCountForAllStores {}
        manager = nil
        userNotificationCenter = nil
        backgroundSynchronizerFactory = nil
        storageManager = nil
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


    /// Verifies that `unregisterForRemoteNotifications` does not dispatch any NotificationAction, whenever the DeviceID is unknown.
    ///
    func testUnregisterForRemoteNotificationsDoesNothingWhenThereIsNoDeviceIdStored() {
        let notificationActionsBefore = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssert(notificationActionsBefore.isEmpty)
        manager.unregisterForRemoteNotifications {}
        let notificationActionsAfter = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssert(notificationActionsAfter.isEmpty)
    }

    /// Verifies that `unregisterForRemoteNotifications` does dispatch `.unregisterDevice` Action, whenever the
    /// deviceID is known.
    ///
    func testUnregisterForRemoteNotificationsEffectivelyDispatchesUnregisterDeviceAction() {
        defaults.set(Sample.deviceID, forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceID)
        manager = makeManager()
        manager.unregisterForRemoteNotifications {}

        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        guard case let .unregisterDevice(deviceID, _) = notificationActions.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(deviceID, Sample.deviceID)
    }


    /// Verifies that `unregisterForRemoteNotifications` does nuke the DeviceID and DeviceToken, whenever the `unregisterDevice`
    /// Action is successful.
    ///
    func testUnregisterForRemoteNotificationsEffectivelyNukesDeviceIdentifierAndTokenOnSuccess() {
        defaults.set(Sample.deviceID, forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceID)
        defaults.set(Sample.deviceToken, forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken)
        manager = makeManager()

        manager.unregisterForRemoteNotifications {}

        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        guard case let .unregisterDevice(_, onCompletion) = notificationActions.first else {
            XCTFail()
            return
        }

        onCompletion(nil)

        XCTAssertNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceID))
        XCTAssertNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken))
    }


    /// Verifies that `registerDeviceToken` effectively stores the Device Token.
    ///
    func testRegisterForRemoteNotificationsStoresDeviceTokenInUserDefaults() async {
        // Given
        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: false, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        manager = makeManager()

        // Wait for eligibility check to complete
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            XCTFail()
            return
        }

        // When
        XCTAssertNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken))
        manager.registerDeviceToken(with: tokenAsData)

        // Then
        XCTAssertNotNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken))
    }

    /// Verifies that `registrationDidFail` enqueues a `unregisterDevice` NotificationAction.
    ///
    func testRegistrationDidFailDispatchesUnregisterDeviceAction() {
        defaults.set(Sample.deviceID, forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceID)
        manager = makeManager()

        manager.registrationDidFail(with: SampleError.first)

        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssertEqual(notificationActions.count, 1)

        switch notificationActions.first {
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
        backgroundSynchronizerFactory.synchronizer.backgroundFetchResult = .newData
        let result = await manager.handleRemoteNotificationInTheBackground(userInfo: payload)

        // Then
        XCTAssertEqual(result, .newData)

        guard case .synchronizeNotifications =
                storesManager.receivedActions.compactMap({ $0 as? NotificationAction }).first else {
            return
        }
    }


    /// Verifies that `handleNotification` dispatches a `synchronizeNotifications` Action, which, in turn, signals that there's
    /// NO New Data available in the app, on error.
    ///
    func testHandleNotificationResultsInSynchronizeNotificationsActionWhichSignalsThatThereIsNoNewDataOnErrorWhenAppStateIsBackground() async {
        // Given
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration)
        }()
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

            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
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

            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
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

            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
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

    func test_handleNotification_does_not_display_inApp_notice_if_no_noteID_in_payload_and_site_registered_with_Woo() async throws {
        // Given
        let siteID: Int64 = 132
        let payload = notificationPayload(siteID: siteID, title: Sample.defaultTitle, message: nil)
        defaults.set("\(siteID)", forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications)
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
        }()

        // When
        application.applicationState = .active
        let notification = try XCTUnwrap(MockNotification(userInfo: payload))
        _ = await manager.handleNotificationInTheForeground(notification)

        // Then
        XCTAssertNil(application.presentInAppMessages.first)
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

            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
        }()

        var emittedNotifications = [WooCommerce.PushNotification]()
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

        var emittedNotifications = [WooCommerce.PushNotification]()
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

            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
        }()

        var emittedNotifications = [WooCommerce.PushNotification]()
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
            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
        }()

        var emittedNotifications = [WooCommerce.PushNotification]()
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
            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
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
            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
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
            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
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
            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
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

    func test_handleNotification_displays_inApp_notice_when_enableInAppNotifications() async throws {
        // Given
        let payload = notificationPayload(title: Sample.defaultTitle,
                                          subtitle: Sample.defaultSubtitle,
                                          message: Sample.defaultMessage)
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
        }()

        application.applicationState = .active
        manager.disableInAppNotifications()

        let notification = try XCTUnwrap(MockNotification(userInfo: payload))
        _ = await manager.handleNotificationInTheForeground(notification)

        XCTAssertTrue(application.presentInAppMessages.isEmpty, "Initial state: No in-app notification is received while disableInAppNotifications")

        // When
        manager.enableInAppNotifications()

        let newNotification = try XCTUnwrap(MockNotification(userInfo: payload))
        _ = await manager.handleNotificationInTheForeground(newNotification)

        // Then
        XCTAssertEqual(application.presentInAppMessages.first?.title, Sample.defaultTitle)
        XCTAssertEqual(application.presentInAppMessages.first?.subtitle, Sample.defaultSubtitle)
        XCTAssertEqual(application.presentInAppMessages.first?.message, Sample.defaultMessage)
    }

    func test_handleNotification_does_not_display_inApp_notice_when_disableInAppNotifications() async throws {
        let payload = notificationPayload(title: Sample.defaultTitle,
                                          subtitle: Sample.defaultSubtitle,
                                          message: Sample.defaultMessage)
        manager = {
            let configuration = PushNotificationsConfiguration(application: self.application,
                                                               defaults: self.defaults,
                                                               storesManager: self.storesManager,
                                                               userNotificationsCenter: self.userNotificationCenter)

            return PushNotificationsManager(configuration: configuration, backgroundSynchronizerFactory: backgroundSynchronizerFactory)
        }()

        // When
        application.applicationState = .active
        manager.disableInAppNotifications()

        let notification = try XCTUnwrap(MockNotification(userInfo: payload))
        _ = await manager.handleNotificationInTheForeground(notification)

        // Then
        XCTAssertTrue(application.presentInAppMessages.isEmpty)
    }

    func test_registerDeviceToken_when_self_driven_gate_enabled_registers_self_driven_token_and_disables_WPCom_notifications() async {
        // Given
        defaults.set("456", forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceID)
        mockSelfDrivenRegistrationActions(token: 123)
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(99)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        manager = makeManager(featureFlagService: featureFlagService)

        // Wait for eligibility check to complete
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            XCTFail("Invalid sample token")
            return
        }

        let registrationExpectation = expectation(description: "Registration completed")
        registrationExpectation.assertForOverFulfill = false
        storesManager.whenReceivingAction(ofType: AccountAction.self) { _ in
            registrationExpectation.fulfill()
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [registrationExpectation], timeout: 1.0)

        // Then
        // It dispatches the self-driven registration action
        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssertTrue(notificationActions.contains(where: {
            if case .registerDeviceForSelfDrivenPushNotifications = $0 { return true }
            return false
        }))

        // It does not clear WPcom token
        XCTAssertNotNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken))

        // It persists Woo token and registered site ID
        XCTAssertNotNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNotificationToken))
        XCTAssertNotNil(defaults.value(forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications))

        // It dispatches the WPCom PN setting update to disable mobile PNs from WPCom for the current siteID and deviceID
        let accountActions = storesManager.receivedActions.compactMap { $0 as? AccountAction }
        XCTAssertTrue(accountActions.contains(where: {
            if case let .updateNotificationSettings(settings, _) = $0,
               let blog = settings.blogs.first(where: { $0.blogID == 99 }),
               let device = blog.devices.first(where: { $0.deviceID == 456 }),
               device.newComment == false,
               device.storeOrder == false {
                return true
            }
            return false
        }))
    }

    func test_registerDeviceToken_when_self_driven_gate_enabled_and_self_driven_token_registration_fails_falls_back_to_wpcom() async {
        // Given
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(99)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        manager = makeManager(featureFlagService: featureFlagService)

        // Wait for eligibility check to complete
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            XCTFail("Invalid sample token")
            return
        }

        let fallbackExpectation = expectation(description: "WPCom fallback triggered")
        fallbackExpectation.assertForOverFulfill = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .registerDeviceForSelfDrivenPushNotifications(_, _, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Failure", code: 404)))
            case .registerDevice:
                fallbackExpectation.fulfill()
            default:
                break
            }
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [fallbackExpectation], timeout: 1.0)

        // Then
        // It dispatches the WPCom device registration request
        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssertTrue(notificationActions.contains(where: {
            if case .registerDevice = $0 { return true }
            return false
        }))
    }

    func test_registerDeviceToken_when_self_driven_registration_fails_with_404_unmarks_registered_site() async {
        // Given
        let siteID: Int64 = 99
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(siteID)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        manager = makeManager(featureFlagService: featureFlagService)

        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        let registrationExpectation = expectation(description: "Registration attempted")
        registrationExpectation.assertForOverFulfill = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(_, _, _, _, _, onCompletion) = action {
                onCompletion(.failure(NetworkError.notFound()))
                registrationExpectation.fulfill()
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [registrationExpectation], timeout: 1.0)

        // Then
        let storedSiteIDs = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        ) ?? ""
        XCTAssertFalse(storedSiteIDs.contains("\(siteID)"), "Site ID should be unmarked after 404 error")
    }

    func test_registerDeviceToken_when_plugin_version_is_incompatible_then_unmarks_site_and_skips_registration() async {
        // Given
        let siteID: Int64 = 99
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(siteID)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        // Set up mock plugin version checker to return incompatible version
        let mockChecker = MockPluginVersionChecker()
        mockChecker.result = .success(.incompatible(currentVersion: "10.5.0", requiredVersion: "10.8.0"))
        let mockCheckerFactory = MockPluginVersionCheckerFactory(checker: mockChecker)

        let versionCheckExpectation = expectation(description: "Version check completed")
        mockChecker.onCheckCompatibility = {
            versionCheckExpectation.fulfill()
        }

        manager = makeManager(featureFlagService: featureFlagService, pluginVersionCheckerFactory: mockCheckerFactory)

        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        // No registration action should be dispatched since version check fails
        var registrationAttempted = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case .registerDeviceForSelfDrivenPushNotifications = action {
                registrationAttempted = true
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [versionCheckExpectation], timeout: 1.0)

        // Then
        XCTAssertFalse(registrationAttempted, "Registration should not be attempted when plugin version is incompatible")
        let storedSiteIDs = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        ) ?? ""
        XCTAssertFalse(storedSiteIDs.contains("\(siteID)"), "Site ID should be unmarked when plugin version is incompatible")
    }

    func test_registerDeviceToken_when_plugin_version_is_compatible_then_proceeds_with_registration() async {
        // Given
        let siteID: Int64 = 99
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(siteID)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        // Set up mock plugin version checker to return compatible version
        let mockChecker = MockPluginVersionChecker()
        mockChecker.result = .success(.compatible)
        let mockCheckerFactory = MockPluginVersionCheckerFactory(checker: mockChecker)

        manager = makeManager(featureFlagService: featureFlagService, pluginVersionCheckerFactory: mockCheckerFactory)

        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        let registrationExpectation = expectation(description: "Registration attempted")
        registrationExpectation.assertForOverFulfill = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(_, _, _, _, _, onCompletion) = action {
                onCompletion(.success(42))
                registrationExpectation.fulfill()
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [registrationExpectation], timeout: 1.0)

        // Then
        let storedSiteIDs = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        ) ?? ""
        XCTAssertTrue(storedSiteIDs.contains("\(siteID)"), "Site ID should be marked as registered when plugin version is compatible")
    }

    func test_registerDeviceToken_when_plugin_version_check_fails_then_proceeds_with_registration() async {
        // Given
        let siteID: Int64 = 99
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(siteID)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        // Set up mock plugin version checker to throw an error
        let mockChecker = MockPluginVersionChecker()
        mockChecker.result = .failure(NSError(domain: "test", code: -1))
        let mockCheckerFactory = MockPluginVersionCheckerFactory(checker: mockChecker)

        manager = makeManager(featureFlagService: featureFlagService, pluginVersionCheckerFactory: mockCheckerFactory)

        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        // Registration should still proceed even when version check fails
        let registrationExpectation = expectation(description: "Registration attempted")
        registrationExpectation.assertForOverFulfill = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(_, _, _, _, _, onCompletion) = action {
                onCompletion(.success(42))
                registrationExpectation.fulfill()
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [registrationExpectation], timeout: 1.0)

        // Then - registration should have proceeded despite version check failure
        let storedSiteIDs = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        ) ?? ""
        XCTAssertTrue(storedSiteIDs.contains("\(siteID)"), "Site ID should be registered even when version check fails")
    }

    func test_registerDeviceToken_when_token_changes_then_clears_registered_sites_before_reregistration() async {
        // Given — site is registered with an old token
        let siteID: Int64 = 99
        defaults.set("\(siteID)", forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications)
        defaults.set("old-token", forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken)
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(siteID)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        manager = makeManager(featureFlagService: featureFlagService)

        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        // Wait for the WPCom fallback (last action in the Task) to ensure the full
        // async registration completes before tearDown nils test properties.
        let fallbackExpectation = expectation(description: "WPCom fallback triggered")
        fallbackExpectation.assertForOverFulfill = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .registerDeviceForSelfDrivenPushNotifications(_, _, _, _, _, onCompletion):
                onCompletion(.failure(NetworkError.unacceptableStatusCode(statusCode: 500)))
            case .registerDevice:
                fallbackExpectation.fulfill()
            default:
                break
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When — new token arrives, clearing previously registered sites
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [fallbackExpectation], timeout: 1.0)

        // Then — site was cleared from registered list due to token change, and re-registration failed
        let storedSiteIDs = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        ) ?? ""
        XCTAssertFalse(storedSiteIDs.contains("\(siteID)"),
                       "Site should be cleared from registered list when token changes")
    }

    // MARK: - Multi-site registration tests

    func test_registerDeviceToken_when_self_driven_enabled_then_registers_all_sites() async {
        // Given
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorage(siteIDs: [100, 200, 300])

        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        var registeredSiteIDs = Set<Int64>()
        let allRegisteredExpectation = expectation(description: "All sites registered")
        allRegisteredExpectation.expectedFulfillmentCount = 3
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(siteID, _, _, _, _, onCompletion) = action {
                registeredSiteIDs.insert(siteID)
                onCompletion(.success(Int64(siteID + 1000)))
                allRegisteredExpectation.fulfill()
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [allRegisteredExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(registeredSiteIDs, [100, 200, 300])

        let storedSiteIDs = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        ) ?? ""
        XCTAssertTrue(storedSiteIDs.contains("100"))
        XCTAssertTrue(storedSiteIDs.contains("200"))
        XCTAssertTrue(storedSiteIDs.contains("300"))
    }

    func test_registerDeviceToken_when_some_sites_fail_then_other_sites_still_registered() async {
        // Given
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorage(siteIDs: [100, 200, 300])

        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        let allAttemptedExpectation = expectation(description: "All sites attempted")
        allAttemptedExpectation.expectedFulfillmentCount = 3
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(siteID, _, _, _, _, onCompletion) = action {
                if siteID == 200 {
                    onCompletion(.failure(NSError(domain: "test", code: 500)))
                } else {
                    onCompletion(.success(Int64(siteID + 1000)))
                }
                allAttemptedExpectation.fulfill()
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [allAttemptedExpectation], timeout: 2.0)

        // Then
        let storedSiteIDs = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        ) ?? ""
        XCTAssertTrue(storedSiteIDs.contains("100"), "Site 100 should be registered")
        XCTAssertTrue(storedSiteIDs.contains("300"), "Site 300 should be registered")
    }

    func test_registerDeviceToken_skips_already_registered_sites() async {
        // Given
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        defaults.set("100,200", forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorage(siteIDs: [100, 200, 300])

        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        var registeredSiteIDs = Set<Int64>()
        let registrationExpectation = expectation(description: "Only unregistered site attempted")
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(siteID, _, _, _, _, onCompletion) = action {
                registeredSiteIDs.insert(siteID)
                onCompletion(.success(Int64(siteID + 1000)))
                registrationExpectation.fulfill()
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [registrationExpectation], timeout: 1.0)

        // Then — only site 300 should have been registered (100 and 200 were already registered)
        XCTAssertEqual(registeredSiteIDs, [300])
    }

    func test_registerDeviceToken_falls_back_to_wpcom_when_any_site_fails() async {
        // Given
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorage(siteIDs: [100, 200])

        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        let fallbackExpectation = expectation(description: "WPCom fallback triggered")
        fallbackExpectation.assertForOverFulfill = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .registerDeviceForSelfDrivenPushNotifications(siteID, _, _, _, _, onCompletion):
                if siteID == 200 {
                    onCompletion(.failure(NSError(domain: "test", code: 500)))
                } else {
                    onCompletion(.success(Int64(siteID + 1000)))
                }
            case .registerDevice:
                fallbackExpectation.fulfill()
            default:
                break
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [fallbackExpectation], timeout: 2.0)

        // Then — WPCom fallback was triggered even though site 100 succeeded, because site 200 failed
        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssertTrue(notificationActions.contains(where: {
            if case .registerDevice = $0 { return true }
            return false
        }))
    }

    func test_registerDeviceToken_when_multiple_sites_then_token_register_events_carry_target_site_properties() async throws {
        // Given — two stored sites with distinct URLs and capability flags; selected site is site 100.
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorageWithCapabilities([
            (siteID: 100, url: "https://alpha.example", isWPCom: true, isJetpackInstalled: true, isJetpackConnected: true),
            (siteID: 200, url: "https://beta.example", isWPCom: false, isJetpackInstalled: false, isJetpackConnected: false)
        ])

        manager = makeManager(featureFlagService: featureFlagService, analytics: analytics)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        // Site 100 succeeds; site 200 fails, which triggers the WPCom fallback we use to sync on flow completion.
        let fallbackExpectation = expectation(description: "WPCom fallback triggered")
        fallbackExpectation.assertForOverFulfill = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .registerDeviceForSelfDrivenPushNotifications(siteID, _, _, _, _, onCompletion):
                if siteID == 200 {
                    onCompletion(.failure(NSError(domain: "test", code: 500)))
                } else {
                    onCompletion(.success(Int64(siteID + 1000)))
                }
            case .registerDevice:
                fallbackExpectation.fulfill()
            default:
                break
            }
        }

        let tokenAsData = try XCTUnwrap(Sample.deviceToken.data(using: .utf8))

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [fallbackExpectation], timeout: 2.0)

        // Then — each event carries the target site's identifiers and capability flags, not the selected site's.
        let successIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "woo_push_token_register_success"),
                                         "Expected a woo_push_token_register_success event for the site that succeeded")
        let successProperties = analyticsProvider.receivedProperties[successIndex]
        XCTAssertEqual(successProperties["blog_id"] as? Int64, 100)
        XCTAssertEqual(successProperties["site_url"] as? String, "https://alpha.example")
        XCTAssertEqual(successProperties["is_wpcom_store"] as? Bool, true)
        XCTAssertEqual(successProperties["is_jetpack_installed"] as? Bool, true)
        XCTAssertEqual(successProperties["is_jetpack_connected"] as? Bool, true)

        let errorIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "woo_push_token_register_error"),
                                       "Expected a woo_push_token_register_error event for the site that failed")
        let errorProperties = analyticsProvider.receivedProperties[errorIndex]
        XCTAssertEqual(errorProperties["blog_id"] as? Int64, 200)
        XCTAssertEqual(errorProperties["site_url"] as? String, "https://beta.example")
        XCTAssertEqual(errorProperties["is_wpcom_store"] as? Bool, false)
        XCTAssertEqual(errorProperties["is_jetpack_installed"] as? Bool, false)
        XCTAssertEqual(errorProperties["is_jetpack_connected"] as? Bool, false)
    }

    func test_registerDeviceToken_when_site_credentials_login_then_token_register_event_uses_session_default_site() async throws {
        // Given — site-credentials style login: the session holds the site, but storage doesn't.
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        storesManager.authenticate(credentials: SessionSettings.wporgCredentials)
        storesManager.sessionManager.setStoreId(500)
        storesManager.updateDefaultStore(Yosemite.Site.fake().copy(
            siteID: 500,
            url: "https://gamma.example",
            isJetpackThePluginInstalled: true,
            isJetpackConnected: false,
            isWordPressComStore: false
        ))
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        // Deliberately do NOT insert any sites into storage — this mirrors the site-creds path
        // where `restoreWordPressSite` writes only to `sessionManager.defaultSite`.

        manager = makeManager(featureFlagService: featureFlagService, analytics: analytics)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        let registrationExpectation = expectation(description: "Site registered")
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(siteID, _, _, _, _, onCompletion) = action {
                onCompletion(.success(Int64(siteID + 1000)))
                registrationExpectation.fulfill()
            }
        }

        let tokenAsData = try XCTUnwrap(Sample.deviceToken.data(using: .utf8))

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [registrationExpectation], timeout: 2.0)

        // Then — the event picks up the session's default site even though storage is empty.
        let successIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "woo_push_token_register_success"),
                                         "Expected a woo_push_token_register_success event")
        let successProperties = analyticsProvider.receivedProperties[successIndex]
        XCTAssertEqual(successProperties["blog_id"] as? Int64, 500)
        XCTAssertEqual(successProperties["site_url"] as? String, "https://gamma.example")
        XCTAssertEqual(successProperties["is_wpcom_store"] as? Bool, false)
        XCTAssertEqual(successProperties["is_jetpack_installed"] as? Bool, true)
        XCTAssertEqual(successProperties["is_jetpack_connected"] as? Bool, false)
    }

    func test_registerDeviceToken_when_site_returns_notFound_then_unmarks_that_site() async {
        // Given
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorage(siteIDs: [100, 200])

        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        let allAttemptedExpectation = expectation(description: "All sites attempted")
        allAttemptedExpectation.expectedFulfillmentCount = 2
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(siteID, _, _, _, _, onCompletion) = action {
                if siteID == 200 {
                    onCompletion(.failure(NetworkError.notFound()))
                } else {
                    onCompletion(.success(Int64(siteID + 1000)))
                }
                allAttemptedExpectation.fulfill()
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [allAttemptedExpectation], timeout: 2.0)

        // Then
        let storedSiteIDs = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        ) ?? ""
        XCTAssertTrue(storedSiteIDs.contains("100"), "Site 100 should be registered")
        XCTAssertFalse(storedSiteIDs.contains("200"), "Site 200 should be unmarked after notFound error")
    }

    func test_registerDeviceToken_when_storage_is_empty_then_falls_back_to_current_siteID() async {
        // Given — no sites in storage, but defaultStoreID is set
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(99)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        // No insertSitesIntoStorage — storage is empty
        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        var registeredSiteIDs = Set<Int64>()
        let registrationExpectation = expectation(description: "Registration attempted")
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(siteID, _, _, _, _, onCompletion) = action {
                registeredSiteIDs.insert(siteID)
                onCompletion(.success(Int64(siteID + 1000)))
                registrationExpectation.fulfill()
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [registrationExpectation], timeout: 1.0)

        // Then — falls back to current siteID (99)
        XCTAssertEqual(registeredSiteIDs, [99])
    }

    func test_registerDeviceToken_when_all_sites_already_registered_then_skips_registration() async {
        // Given — all sites already registered
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        defaults.set("100,200", forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications)
        // Set the same device token so token-change logic doesn't clear sites
        defaults.set(Sample.deviceToken.data(using: .utf8)!.hexString,
                     forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorage(siteIDs: [100, 200])

        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        var registrationAttempted = false
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case .registerDeviceForSelfDrivenPushNotifications = action {
                registrationAttempted = true
            }
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)

        // Give time for any async work to run
        try? await Task.sleep(for: .milliseconds(100))

        // Then — no registration action dispatched (all sites already registered)
        XCTAssertFalse(registrationAttempted, "Should not attempt registration when all sites are already registered")
    }

    func test_registerDeviceToken_when_eligibility_unknown_then_retries_eligibility_check() async {
        // Given — eligibility check does not complete during init
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(99)

        // Do NOT set up mockRemoteFeatureFlagAction yet — eligibility stays nil
        manager = makeManager()

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When — first call stores pending token since eligibility is nil
        manager.registerDeviceToken(with: tokenAsData)

        // Then — set up the mock so the re-triggered check can complete
        let registrationExpectation = expectation(description: "Registration completed after eligibility resolved")
        registrationExpectation.assertForOverFulfill = false
        mockRemoteFeatureFlagAction(isEnabled: true)
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .registerDeviceForSelfDrivenPushNotifications(_, _, _, _, _, onCompletion) = action {
                onCompletion(.success(42))
                registrationExpectation.fulfill()
            }
        }

        // The re-triggered eligibility check should complete and process the pending token
        await fulfillment(of: [registrationExpectation], timeout: 2.0)

        // Then — registration was dispatched after eligibility resolved
        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssertTrue(notificationActions.contains(where: {
            if case .registerDeviceForSelfDrivenPushNotifications = $0 { return true }
            return false
        }))
    }

    func test_registerDeviceToken_when_self_driven_succeeds_and_deviceID_is_nil_then_registers_dotcom_and_disables_WPCom() async throws {
        // Given
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorage(siteIDs: [100])

        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        // Decode a DotcomDevice with a fresh deviceID to return from the fallback Dotcom registration
        let dotcomDeviceJSON = #"{"ID": "789"}"#.data(using: .utf8)!
        let freshDotcomDevice = try JSONDecoder().decode(DotcomDevice.self, from: dotcomDeviceJSON)

        let dotcomExpectation = expectation(description: "Dotcom registerDevice dispatched")
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .registerDeviceForSelfDrivenPushNotifications(_, _, _, _, _, onCompletion):
                onCompletion(.success(123))
            case let .registerDevice(_, _, _, onCompletion):
                dotcomExpectation.fulfill()
                onCompletion(freshDotcomDevice, nil)
            default:
                break
            }
        }

        let disableExpectation = expectation(description: "WPCom disable dispatched")
        storesManager.whenReceivingAction(ofType: AccountAction.self) { _ in
            disableExpectation.fulfill()
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [dotcomExpectation, disableExpectation], timeout: 2.0)

        // Then
        // It falls back to Dotcom registration to obtain a deviceID
        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssertTrue(notificationActions.contains(where: {
            if case .registerDevice = $0 { return true }
            return false
        }))

        // It disables WPCom PNs for the Woo-registered site using the fresh deviceID (789)
        let accountActions = storesManager.receivedActions.compactMap { $0 as? AccountAction }
        XCTAssertTrue(accountActions.contains(where: {
            if case let .updateNotificationSettings(settings, _) = $0,
               let blog = settings.blogs.first(where: { $0.blogID == 100 }),
               let device = blog.devices.first(where: { $0.deviceID == 789 }),
               device.newComment == false,
               device.storeOrder == false {
                return true
            }
            return false
        }))
    }

    func test_registerDeviceToken_when_self_driven_succeeds_and_deviceID_is_set_then_disables_WPCom_without_dotcom_registration() async {
        // Given
        defaults.set("456", forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceID)
        mockSelfDrivenRegistrationActions(token: 123)
        storesManager.authenticate(credentials: SessionSettings.wpcomCredentials)
        storesManager.sessionManager.setStoreId(100)
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)

        let eligibilityCheckExpectation = expectation(description: "Eligibility check completed")
        mockRemoteFeatureFlagAction(isEnabled: true, onCompletion: {
            eligibilityCheckExpectation.fulfill()
        })

        await insertSitesIntoStorage(siteIDs: [100])

        manager = makeManager(featureFlagService: featureFlagService)
        await fulfillment(of: [eligibilityCheckExpectation], timeout: 1.0)

        let disableExpectation = expectation(description: "WPCom disable dispatched")
        storesManager.whenReceivingAction(ofType: AccountAction.self) { _ in
            disableExpectation.fulfill()
        }

        guard let tokenAsData = Sample.deviceToken.data(using: .utf8) else {
            return XCTFail("Invalid sample token")
        }

        // When
        manager.registerDeviceToken(with: tokenAsData)
        await fulfillment(of: [disableExpectation], timeout: 2.0)

        // Then
        // It disables WPCom PNs using the existing deviceID (456)
        let accountActions = storesManager.receivedActions.compactMap { $0 as? AccountAction }
        XCTAssertTrue(accountActions.contains(where: {
            if case let .updateNotificationSettings(settings, _) = $0,
               let blog = settings.blogs.first(where: { $0.blogID == 100 }),
               let device = blog.devices.first(where: { $0.deviceID == 456 }),
               device.newComment == false,
               device.storeOrder == false {
                return true
            }
            return false
        }))

        // It does NOT re-register with Dotcom since deviceID was already present
        let notificationActions = storesManager.receivedActions.compactMap { $0 as? NotificationAction }
        XCTAssertFalse(notificationActions.contains(where: {
            if case .registerDevice = $0 { return true }
            return false
        }))
    }
}


// MARK: - Private Methods
//
private extension PushNotificationsManagerTests {
    func makeManager(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     storageManager: MockStorageManager? = nil,
                     pluginVersionCheckerFactory: PluginVersionCheckerFactoryProtocol? = nil,
                     analytics: Analytics = ServiceLocator.analytics) -> PushNotificationsManager {
        // Capture strong local references so the @autoclosure closures in
        // PushNotificationsConfiguration don't go through the test's IUO
        // properties, which may be nilled in tearDown while async Tasks are still in flight.
        let application = self.application!
        let defaults = self.defaults!
        let storesManager = self.storesManager!
        let userNotificationCenter = self.userNotificationCenter!

        let configuration = PushNotificationsConfiguration(application: application,
                                                           defaults: defaults,
                                                           storesManager: storesManager,
                                                           userNotificationsCenter: userNotificationCenter)

        return PushNotificationsManager(configuration: configuration,
                                        backgroundSynchronizerFactory: backgroundSynchronizerFactory,
                                        analytics: analytics,
                                        storageManager: storageManager ?? self.storageManager,
                                        featureFlagService: featureFlagService,
                                        pluginVersionCheckerFactory: pluginVersionCheckerFactory ?? MockPluginVersionCheckerFactory())
    }


    /// Returns a Sample Notification Payload
    ///
    func notificationPayload(badgeCount: Int = 0,
                             noteID: Int64? = 1234,
                             type: Note.Kind = .comment,
                             siteID: Int64 = 134,
                             title: String = Sample.defaultTitle,
                             subtitle: String? = nil,
                             message: String? = nil) -> [String: Any] {
        var payload: [String: Any] = [
            "aps": [
                "badge": badgeCount,
                "alert": [
                    "title": title,
                    "subtitle": subtitle,
                    "body": message
                ]
            ] as [String: Any],
            "type": type.rawValue,
            "blog": siteID
        ]
        if let noteID {
            payload["note_id"] = noteID
        }
        return payload
    }

    func mockSynchronizeNotificationsAction(error: Error? = nil) {
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case .synchronizeNotifications(let completion) = action {
                completion(error)
            }
        }
    }

    func mockSelfDrivenRegistrationActions(token: Int64 = 42, error: Error? = nil) {
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case .registerDeviceForSelfDrivenPushNotifications(_, _, _, _, _, let completion):
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(token))
                }

            case .unregisterDevice(let deviceID, let onCompletion):
                XCTAssertEqual(deviceID, "wpcom-device-id")
                onCompletion(nil)

            default:
                break
            }
        }
    }

    func mockRemoteFeatureFlagAction(isEnabled: Bool, onCompletion: (() -> Void)? = nil) {
        storesManager.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case .isRemoteFeatureFlagEnabled(_, _, _, let completion):
                completion(isEnabled)
                onCompletion?()
            }
        }
    }

    func insertSitesIntoStorage(siteIDs: [Int64]) async {
        await storageManager.performAndSaveAsync({ storage in
            for siteID in siteIDs {
                let site = storage.insertNewObject(ofType: Site.self)
                site.siteID = siteID
                site.isWooCommerceActive = NSNumber(value: true)
            }
        })
    }

    func insertSitesIntoStorageWithCapabilities(
        _ sites: [(siteID: Int64, url: String, isWPCom: Bool, isJetpackInstalled: Bool, isJetpackConnected: Bool)]
    ) async {
        await storageManager.performAndSaveAsync({ storage in
            for descriptor in sites {
                let site = storage.insertNewObject(ofType: Site.self)
                site.siteID = descriptor.siteID
                site.url = descriptor.url
                site.isWooCommerceActive = NSNumber(value: true)
                site.isWordPressStore = NSNumber(value: descriptor.isWPCom)
                site.isJetpackThePluginInstalled = descriptor.isJetpackInstalled
                site.isJetpackConnected = descriptor.isJetpackConnected
            }
        })
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

// MARK: - Mocks

private class MockPushNotificationBackgroundSynchronizer: PushNotificationBackgroundSynchronizerProtocol {
    var backgroundFetchResult: UIBackgroundFetchResult = .noData
    func sync() async -> UIBackgroundFetchResult {
        return backgroundFetchResult
    }
}

private class MockPushNotificationBackgroundSynchronizerFactory: PushNotificationBackgroundSynchronizerFactoryProtocol {
    var synchronizer = MockPushNotificationBackgroundSynchronizer()
    func make(userInfo: [AnyHashable: Any], stores: StoresManager) -> any PushNotificationBackgroundSynchronizerProtocol {
        return synchronizer
    }
}

private class MockPluginVersionCheckerFactory: PluginVersionCheckerFactoryProtocol {
    let checker: MockPluginVersionChecker

    init(checker: MockPluginVersionChecker = MockPluginVersionChecker()) {
        self.checker = checker
    }

    func makeChecker(siteID: Int64, pluginPath: String, minimumVersion: String) -> PluginVersionCheckerProtocol {
        return checker
    }
}
