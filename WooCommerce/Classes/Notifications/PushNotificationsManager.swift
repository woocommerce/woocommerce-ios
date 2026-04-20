import Combine
import Experiments
import Foundation
import UserNotifications
import AutomatticTracks
import Yosemite
import WooFoundation
import enum NetworkingCore.NetworkError
import protocol Storage.StorageManagerType


/// PushNotificationsManager: Encapsulates all the tasks related to Push Notifications Auth + Registration + Handling.
///
final class PushNotificationsManager: PushNotesManager {

    private var inAppNotices: Bool = true

    func disableInAppNotifications() {
        inAppNotices = false
    }

    func enableInAppNotifications() {
        inAppNotices = true
    }

    /// PushNotifications Configuration
    ///
    let configuration: PushNotificationsConfiguration

    /// An observable that emits values when the Remote Notifications are received while the app is
    /// in the foreground.
    ///
    var foregroundNotifications: AnyPublisher<PushNotification, Never> {
        foregroundNotificationsSubject.eraseToAnyPublisher()
    }

    /// Mutable reference to `foregroundNotifications`.
    private let foregroundNotificationsSubject = PassthroughSubject<PushNotification, Never>()

    /// An observable that emits values when the user taps to view the in-app notification while the app is
    /// in the foreground.
    ///
    var foregroundNotificationsToView: AnyPublisher<PushNotification, Never> {
        foregroundNotificationsToViewSubject.eraseToAnyPublisher()
    }

    /// Mutable reference to `foregroundNotificationsToView`.
    private let foregroundNotificationsToViewSubject = PassthroughSubject<PushNotification, Never>()

    /// An observable that emits values when a Remote Notification is received while the app is
    /// in inactive.
    ///
    var inactiveNotifications: AnyPublisher<PushNotification, Never> {
        inactiveNotificationsSubject.eraseToAnyPublisher()
    }

    /// Mutable reference to `inactiveNotifications`
    private let inactiveNotificationsSubject = PassthroughSubject<PushNotification, Never>()

    /// An observable that emits values when a Remote Notification is received while the app is
    /// in the background.
    ///
    var backgroundNotifications: AnyPublisher<PushNotification, Never> {
        backgroundNotificationsSubject.eraseToAnyPublisher()
    }

    /// Mutable reference to `backgroundNotifications`
    private let backgroundNotificationsSubject = PassthroughSubject<PushNotification, Never>()

    /// An observable that emits values when a local notification is received.
    ///
    var localNotificationUserResponses: AnyPublisher<UNNotificationResponse, Never> {
        localNotificationResponsesSubject.eraseToAnyPublisher()
    }

    /// Mutable reference to `localNotificationResponses`.
    private let localNotificationResponsesSubject = PassthroughSubject<UNNotificationResponse, Never>()

    /// Returns the current Application's State
    ///
    private var applicationState: UIApplication.State {
        return configuration.application.applicationState
    }

    private let registrationState: PushNotificationRegistrationState

    /// WordPress.com Device Identifier
    ///
    var deviceID: String? {
        registrationState.deviceID
    }

    /// Site IDs registered to Woo PN system.
    ///
    var siteIDsRegisteredForWooPNs: [Int64] {
        registrationState.siteIDsRegisteredForWooPNs
    }

    var siteIDsRegisteredForWooPNsPublisher: AnyPublisher<[Int64], Never> {
        registrationState.siteIDsRegisteredForWooPNsPublisher
    }

    var hasStoredSiteIDsRegisteredForWooPNs: Bool {
        registrationState.hasStoredSiteIDsRegisteredForWooPNs
    }

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    private var stores: StoresManager {
        configuration.storesManager
    }

    private let analytics: Analytics
    private let storageManager: StorageManagerType

    private let backgroundSynchronizerFactory: PushNotificationBackgroundSynchronizerFactoryProtocol
    private let selfDriventPNEligiblityChecker: WooPushNotificationEligibilityCheck
    private let pluginVersionCheckerFactory: PluginVersionCheckerFactoryProtocol
    private var selfDrivenPushNotificationEnabled: Bool?
    private var pendingTokenData: Data?

    /// Holds the latest device token result, delivered asynchronously via `registerDeviceToken(with:)` or `registrationDidFail(with:)`.
    /// Starts as `nil` (no result yet). `waitForDeviceToken()` reads `.value` for an immediate result
    /// or subscribes for the first non-nil emission.
    private let deviceTokenResult = CurrentValueSubject<Result<String, Error>?, Never>(nil)

    /// Whether `registerDeviceAndWaitForTokenAcceptance()` is actively waiting for a token.
    /// When true, `registerDeviceToken(with:)` skips its own registration path
    /// because the awaited flow handles it.
    private var isAwaitingTokenForRegistration = false

    /// Initializes the PushNotificationsManager.
    ///
    /// - Parameter configuration: PushNotificationsConfiguration Instance that should be used.
    ///
    init(configuration: PushNotificationsConfiguration = .default,
         backgroundSynchronizerFactory: PushNotificationBackgroundSynchronizerFactoryProtocol = PushNotificationBackgroundSynchronizerFactory(),
         analytics: Analytics = ServiceLocator.analytics,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         pluginVersionCheckerFactory: PluginVersionCheckerFactoryProtocol = PluginVersionCheckerFactory()) {
        self.configuration = configuration
        self.registrationState = PushNotificationRegistrationState(defaults: configuration.defaults, log: { DDLogInfo($0) })
        self.backgroundSynchronizerFactory = backgroundSynchronizerFactory
        self.analytics = analytics
        self.storageManager = storageManager
        self.pluginVersionCheckerFactory = pluginVersionCheckerFactory
        self.selfDriventPNEligiblityChecker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: configuration.storesManager
        )
        checkSelfDrivenPushNotificationsEligibility()
    }
}


// MARK: - Public Methods
//
extension PushNotificationsManager {

    /// Requests Authorization to receive Push Notifications, *only* when the current Status is not determined or provisional.
    ///
    /// - Parameter onCompletion: Closure to be executed on completion. Receives a Boolean indicating if we've got Push Permission.
    ///
    func ensureAuthorizationIsRequested(includesProvisionalAuth: Bool = false, onCompletion: ((Bool) -> Void)? = nil) {
        let nc = configuration.userNotificationsCenter

        nc.loadAuthorizationStatus(queue: .main) { [weak self] status in
            guard status == .notDetermined || status == .provisional else {
                onCompletion?(status == .authorized)
                return
            }

            nc.requestAuthorization(queue: .main, includesProvisionalAuth: includesProvisionalAuth) { [weak self] allowed in
                let stat: WooAnalyticsStat = allowed ? .pushNotificationOSAlertAllowed : .pushNotificationOSAlertDenied
                self?.analytics.track(stat)

                onCompletion?(allowed)
            }

            self?.analytics.track(.pushNotificationOSAlertShown)
        }
    }


    /// Registers the Application for Remote Notifications.
    ///
    func registerForRemoteNotifications() {
        DDLogInfo("📱 Registering for Remote Notifications...")
        configuration.application.registerForRemoteNotifications()
    }

    /// Registers for remote notifications, requests authorization, waits for the device token,
    /// and sends it to the push-tokens endpoint.
    /// - Returns: The token ID on success.
    /// - Throws: If any step in the registration pipeline fails.
    @MainActor
    func registerDeviceAndWaitForTokenAcceptance() async throws -> Int64 {
        #if targetEnvironment(simulator)
        if !isRunningTests {
            DDLogVerbose("👀 Push Notifications tokens are not supported in the Simulator - mocking success result")
            let mockTokenID = Int64.random(in: 99...9999)
            registrationState.setWooPushNotificationTokenID(mockTokenID)
            if let siteID {
                registrationState.markSiteAsRegisteredForWooPNs(siteID)
            }
            return mockTokenID
        }
        #endif

        // Reset any previous token result before starting a new registration
        deviceTokenResult.send(nil)

        // 1. Register with iOS for remote notifications
        registerForRemoteNotifications()

        // 2. Request authorization
        let _ = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            ensureAuthorizationIsRequested(includesProvisionalAuth: false) { granted in
                continuation.resume(returning: granted)
            }
        }

        // 3. Wait for device token from iOS
        let deviceToken = try await waitForDeviceToken()

        // 4. Send token to endpoint and wait for acceptance
        guard let siteID else {
            throw PushNotificationError.missingSiteID
        }
        return try await withCheckedThrowingContinuation { continuation in
            registerSelfDrivenPushNotificationFlow(with: deviceToken, siteID: siteID) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Waits for the device token to arrive via `registerDeviceToken(with:)`.
    /// Returns immediately if a result is already available, otherwise subscribes
    /// to `deviceTokenResult` with a 10-second timeout.
    @MainActor
    private func waitForDeviceToken() async throws -> String {
        isAwaitingTokenForRegistration = true

        defer {
            isAwaitingTokenForRegistration = false
        }

        if let existing = deviceTokenResult.value {
            return try existing.get()
        }

        guard
            let result = await deviceTokenResult
                .compactMap({ $0 })
                .timeout(.seconds(10), scheduler: DispatchQueue.main)
                .values
                .first(where: { _ in true })
        else {
            throw PushNotificationError.deviceTokenTimeout
        }

        return try result.get()
    }


    /// Unregisters the Application from both Woo and WordPress.com Push Notifications Services.
    ///
    func unregisterForRemoteNotifications(onCompletion: @escaping () -> Void) {
        DDLogInfo("📱 Unregistering For Remote Notifications...")

        let group = DispatchGroup()

        if selfDrivenPushNotificationEnabled == true {
            group.enter()
            unregisterFromWooPushNotificationsIfPossible { result in
                switch result {
                case .success:
                    DDLogInfo("📱 Successfully unregistered from Woo Push Notifications!")
                case .failure(let error):
                    DDLogError("⛔️ Unable to unregister from Woo Push Notifications: \(error)")
                }
                self.registrationState.clearWooRegistration()
                group.leave()
            }
        }

        if stores.isAuthenticatedWithoutWPCom == false {
            group.enter()
            unregisterDotcomDeviceIfPossible() { error in
                if let error = error {
                    DDLogError("⛔️ Unable to unregister from WordPress.com Push Notifications: \(error)")
                } else {
                    DDLogInfo("📱 Successfully unregistered from WordPress.com Push Notifications!")
                }
                self.registrationState.clearWPComRegistration()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            onCompletion()
        }
    }


    /// Resets the Badge Count.
    ///
    func resetBadgeCount(type: Note.Kind) {
        guard let siteID = siteID else {
            return
        }
        let action = NotificationCountAction.reset(siteID: siteID, type: type) { [weak self] in
            self?.loadNotificationCountAndUpdateApplicationBadgeNumber(siteID: siteID, type: type, postNotifications: false)
        }
        stores.dispatch(action)
    }

    func resetBadgeCountForAllStores(onCompletion: @escaping () -> Void) {
        let action = NotificationCountAction.resetForAllSites() { [weak self] in
            guard let self = self else { return }
            self.configuration.application.applicationIconBadgeNumber = AppIconBadgeNumber.clearsBadgeAndPotentiallyAllPushNotifications
            self.removeAllNotifications()
            onCompletion()
        }
        stores.dispatch(action)
    }

    func reloadBadgeCount() {
        guard let siteID = siteID else {
            return
        }
        loadNotificationCountAndUpdateApplicationBadgeNumber(siteID: siteID, type: nil, postNotifications: true)
    }

    /// Registers the Device Token agains WordPress.com backend, if there's a default account.
    ///
    /// - Parameters:
    ///     - tokenData: APNS's Token Data
    ///     - defaultStoreID: Default WooCommerce Store ID
    ///
    func registerDeviceToken(with tokenData: Data) {
        // Always publish the token so `waitForDeviceToken()` can pick it up,
        // even when eligibility is not yet determined.
        deviceTokenResult.send(.success(tokenData.hexString))

        guard let selfDrivenPushNotificationEnabled else {
            DDLogDebug("📱 Self-driven eligibility not yet determined — storing token and re-checking")
            pendingTokenData = tokenData
            checkSelfDrivenPushNotificationsEligibility()
            return
        }
        let newToken = tokenData.hexString

        // When the device token changes, clear registered site IDs so all sites
        // re-register with the new token.
        if let existingToken = registrationState.deviceToken, existingToken != newToken {
            DDLogDebug("📱 Device token changed — clearing registered site IDs for re-registration")
            for siteID in registrationState.siteIDsRegisteredForWooPNs {
                registrationState.unmarkSiteAsRegisteredForWooPNs(siteID)
            }
        }

        registrationState.applyNewDeviceToken(newToken)

        // The awaited flow handles its own registration,
        // so skip the existing path below.
        if isAwaitingTokenForRegistration {
            return
        }

        func registerForWPComPushNotificationsIfPossible() {
            if stores.isAuthenticatedWithoutWPCom { return }
            // Register in the Dotcom's Infrastructure
            registerDotcomDevice(with: newToken) { (device, error) in
                guard let deviceID = device?.deviceID else {
                    DDLogError("⛔️ Dotcom Push Notifications Registration Failure: \(error.debugDescription)")
                    return
                }

                DDLogVerbose("📱 Successfully registered Device ID \(deviceID) for Push Notifications")
                self.registrationState.deviceID = deviceID
                self.disableWPComPushNotificationsIfNeeded(siteIDs: self.registrationState.siteIDsRegisteredForWooPNs, deviceID: deviceID)
            }
        }

        if selfDrivenPushNotificationEnabled {
            DDLogInfo("📱 Self Registering Push Notifications for all sites")
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await registerSelfDrivenPushNotificationsForAllSites(with: newToken)
                    // Disable WPCom PNs for successfully registered sites
                    if let deviceID = registrationState.deviceID {
                        disableWPComPushNotificationsIfNeeded(
                            siteIDs: registrationState.siteIDsRegisteredForWooPNs,
                            deviceID: deviceID
                        )
                    } else {
                        // Register with WPCom to get deviceID for disabling
                        registerForWPComPushNotificationsIfPossible()
                    }
                } catch {
                    registerForWPComPushNotificationsIfPossible()
                }
            }
        } else {
            registerForWPComPushNotificationsIfPossible()
        }
    }


    /// Handles Push Notifications Registration Errors. This method unregisters the current device from the WordPress.com
    /// Push Service.
    ///
    /// - Parameter error: Error received after attempting to register for Push Notifications.
    ///
    func registrationDidFail(with error: Error) {
        DDLogError("⛔️ Push Notifications Registration Failure: \(error)")

        // Always publish the failure so `waitForDeviceToken()` can pick it up,
        // matching the symmetric behavior in `registerDeviceToken(with:)`.
        deviceTokenResult.send(.failure(error))

        guard !isAwaitingTokenForRegistration else {
            return
        }

        unregisterForRemoteNotifications {}
    }

    /// Handles a notification while the app is in foreground
    ///
    /// - Parameter notification: The delivered `UNNotification`
    /// - Returns: `UNNotificationPresentationOptions` indicating how (if at all) the system should present its own UI for this notification
    ///
    @MainActor
    func handleNotificationInTheForeground(_ notification: UNNotification) async -> UNNotificationPresentationOptions {
        let content = notification.request.content
        // Check if this is a local notification
        if !content.isRemoteNotification {
            // Display local notifications with banner and sound when app is in foreground
            let identifier = notification.request.identifier
            analytics.track(event: .LocalNotification.displayed(type: LocalNotification.Scenario.identifierForAnalytics(identifier),
                                                                userInfo: content.userInfo))
            return [.banner, .sound, .list]
        }

        guard applicationState == .active, content.isRemoteNotification, inAppNotices == true else {
            // Remote notifications not handled when the app is not active, or in-app notices are disabled
            return UNNotificationPresentationOptions(rawValue: 0)
        }

        handleRemoteNotificationInAllAppStates(content.userInfo)

        if let foregroundNotification = PushNotification.from(userInfo: content.userInfo) {
            if registrationState.isSiteRegisteredForWooPNs(foregroundNotification.siteID),
               foregroundNotification.noteID != nil {
                // Ignore WPCom PNs if site is registered for Woo PNs
                return []
            }
            configuration.application
                .presentInAppNotification(title: foregroundNotification.title,
                                          subtitle: foregroundNotification.subtitle,
                                          message: foregroundNotification.message,
                                          actionTitle: Localization.viewInAppNotification) { [weak self] in
                    guard let self = self else { return }
                    self.presentDetails(for: foregroundNotification)
                    self.foregroundNotificationsToViewSubject.send(foregroundNotification)
                    self.analytics.track(.viewInAppPushNotificationPressed,
                                                   withProperties: [AnalyticKey.type: foregroundNotification.kind.rawValue])
                }

            foregroundNotificationsSubject.send(foregroundNotification)
        }

        _ = await synchronizeNotifications()
        return UNNotificationPresentationOptions(rawValue: 0)
    }

    @MainActor
    func handleUserResponseToNotification(_ response: UNNotificationResponse) async {
        // Remote notification response is handled separately.
        if let notification = PushNotification.from(userInfo: response.notification.request.content.userInfo) {
            handleRemoteNotificationInAllAppStates(response.notification.request.content.userInfo)
            await handleInactiveRemoteNotification(notification: notification)
        } else {
            localNotificationResponsesSubject.send(response)
        }
    }

    /// Handles a remote notification while the app is in the background.
    ///
    /// - Parameter userInfo: The notification's payload.
    /// - Returns: Whether there is any data fetched in the background.
    @MainActor
    func handleRemoteNotificationInTheBackground(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard applicationState == .background, // Proceeds only if the app is in background.
              let _ = userInfo[APNSKey.identifier] // Ensures that we are only processing a remote notification.
        else {
            return .noData
        }

        handleRemoteNotificationInAllAppStates(userInfo)

        if let notification = PushNotification.from(userInfo: userInfo) {
            backgroundNotificationsSubject.send(notification)
        }

        return await backgroundSynchronizerFactory.make(userInfo: userInfo, stores: configuration.storesManager).sync()
    }

    func requestLocalNotification(_ notification: LocalNotification, trigger: UNNotificationTrigger?) async {
        let center = configuration.userNotificationsCenter
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            DDLogError("⛔️ Unable to request a local notification due to invalid authorization status: \(settings.authorizationStatus)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.userInfo = notification.userInfo

        if let categoryAndActions = notification.actions {
            let categoryIdentifier = categoryAndActions.category.rawValue
            let actions = categoryAndActions.actions.map {
                UNNotificationAction(identifier: $0.rawValue,
                                     title: $0.title,
                                     options: .foreground)
            }
            let category = UNNotificationCategory(identifier: categoryIdentifier,
                                                  actions: actions,
                                                  intentIdentifiers: [],
                                                  hiddenPreviewsBodyPlaceholder: nil,
                                                  categorySummaryFormat: nil,
                                                  // `customDismissAction` option is required for the dismiss action callback in
                                                  // `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:)`
                                                  // with action identifier `UNNotificationDismissActionIdentifier`.
                                                  options: .customDismissAction)
            center.setNotificationCategories([category])
            content.categoryIdentifier = categoryIdentifier
        }

        let request = UNNotificationRequest(identifier: notification.scenario.identifier,
                                            content: content,
                                            trigger: trigger)
        do {
            try await center.add(request)
            analytics.track(event: .LocalNotification.scheduled(type: LocalNotification.Scenario.identifierForAnalytics(notification.scenario.identifier),
                                                                userInfo: notification.userInfo))
        } catch {
            DDLogError("⛔️ Unable to request a local notification: \(error)")
        }
    }

    func requestLocalNotificationIfNeeded(_ notification: LocalNotification, trigger: UNNotificationTrigger?) async {
        let center = configuration.userNotificationsCenter
        let pendingNotifications = await center.pendingNotificationRequests()
        let identifier = notification.scenario.identifier
        if pendingNotifications.map(\.identifier).contains(identifier) {
            return
        }
        await requestLocalNotification(notification, trigger: trigger)
    }

    func cancelLocalNotification(scenarios: [LocalNotification.Scenario]) async {
        let center = configuration.userNotificationsCenter
        let pending = await center.pendingNotificationRequests().filter {
            scenarios.map { LocalNotification.Scenario.identifierForAnalytics($0.identifier) }
                .contains(LocalNotification.Scenario.identifierForAnalytics($0.identifier))
        }
        center.removePendingNotificationRequests(withIdentifiers: pending.map { $0.identifier })
        pending.forEach { request in
            analytics.track(event: .LocalNotification.canceled(type: LocalNotification.Scenario.identifierForAnalytics(request.identifier),
                                                               userInfo: request.content.userInfo))
        }
    }

    func cancelAllNotifications() async {
        let center = configuration.userNotificationsCenter
        let pendingNotifications = await center.pendingNotificationRequests()
        removeAllNotifications()
        pendingNotifications.forEach { request in
            analytics.track(event: .LocalNotification.canceled(type: LocalNotification.Scenario.identifierForAnalytics(request.identifier),
                                                               userInfo: request.content.userInfo))
        }
    }
}

// MARK: - Notification count & app badge number update
//
private extension PushNotificationsManager {
    func incrementNotificationCount(siteID: Int64, type: Note.Kind, incrementCount: Int, onCompletion: @escaping () -> Void) {
        let action = NotificationCountAction.increment(siteID: siteID, type: type, incrementCount: incrementCount, onCompletion: onCompletion)
        stores.dispatch(action)
    }

    func loadNotificationCountAndUpdateApplicationBadgeNumber(siteID: Int64, type: Note.Kind?, postNotifications: Bool) {
        loadNotificationCountAndUpdateApplicationBadgeNumber(siteID: siteID)
        if postNotifications {
            postBadgeReloadNotifications(type: type)
        }
    }

    func loadNotificationCountAndUpdateApplicationBadgeNumber(siteID: Int64) {
        let action = NotificationCountAction.load(siteID: siteID, type: .allKinds) { [weak self] count in
            self?.configuration.application.applicationIconBadgeNumber = count > 0 ?
                AppIconBadgeNumber.hasUnreadPushNotifications: AppIconBadgeNumber.clearsBadgeOnly
        }
        stores.dispatch(action)
    }

    func postBadgeReloadNotifications(type: Note.Kind?) {
        guard let type = type else {
            postBadgeReloadNotification(type: .comment)
            postBadgeReloadNotification(type: .storeOrder)
            return
        }
        postBadgeReloadNotification(type: type)
    }

    func postBadgeReloadNotification(type: Note.Kind) {
        switch type {
        case .comment:
            NotificationCenter.default.post(name: .reviewsBadgeReloadRequired, object: nil)
        case .storeOrder:
            NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
        default:
            break
        }
    }

    func removeAllNotifications() {
        configuration.userNotificationsCenter.removeAllNotifications()
    }
}

// MARK: - Push Handlers
//
private extension PushNotificationsManager {

    /// Handles a Support Remote Notification
    ///
    /// - Note: This should actually be *private*. BUT: for unit testing purposes we'll have to keep it public. Sorry.
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    /// - Returns: True when handled. False otherwise
    ///
    func handleSupportNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard userInfo.string(forKey: APNSKey.type) == PushType.zendesk else {
            return false
        }

        trackNotification(with: userInfo)
        return true
    }

    /// Handles a Remote Push Notification Payload regardless of the application state.
    ///
    func handleRemoteNotificationInAllAppStates(_ userInfo: [AnyHashable: Any]) {
        DDLogVerbose("📱 Push Notification Received: \n\(userInfo)\n")

        if let typeString = userInfo.string(forKey: APNSKey.type),
           let type = Note.Kind(rawValue: typeString),
           let siteID = siteID,
           let notificationSiteID = userInfo[APNSKey.siteID] as? Int64 {
            // Badge: Update
            incrementNotificationCount(siteID: notificationSiteID, type: type, incrementCount: 1) { [weak self] in
                self?.loadNotificationCountAndUpdateApplicationBadgeNumber(siteID: siteID, type: type, postNotifications: true)
            }

            // Update related product when review notification is received
            if type == .comment, let productID = userInfo[APNSKey.postID] as? Int64 {
                updateProduct(productID, siteID: notificationSiteID)
            }
        }

        // Badge: Reset
        guard userInfo.string(forKey: APNSKey.type) != PushType.badgeReset else {
            return
        }

        // Analytics
        trackNotification(with: userInfo)

        // Handles support notification in different app states.
        // Note: support notifications are currently not working - https://github.com/woocommerce/woocommerce-ios/issues/3776
        _ = handleSupportNotification(userInfo)
    }

    /// Handles a remote notification while the app is inactive.
    ///
    /// - Parameter notification: Push notification content from a remote notification.
    @MainActor
    func handleInactiveRemoteNotification(notification: WooCommerce.PushNotification) async {
        guard applicationState == .inactive else {
            return
        }

        DDLogVerbose("📱 Handling Remote Notification in Inactive State")

        presentDetails(for: notification)

        inactiveNotificationsSubject.send(notification)
    }

    /// Reload related product when review notification is received
    ///
    func updateProduct(_ productID: Int64, siteID: Int64) {
        let action = ProductAction.retrieveProduct(siteID: siteID,
                                                   productID: productID) { _ in
            // ResultsController<StorageProduct> will reload the Product List (ProductsViewController)
        }
        stores.dispatch(action)
    }
}

private extension PushNotificationsManager {
    func presentDetails(for notification: PushNotification) {
        if notification.kind != .comment {
            configuration.application.presentNotificationDetails(notification: notification)
        }
    }
}


// MARK: - Dotcom Device Registration
//
private extension PushNotificationsManager {

    func checkSelfDrivenPushNotificationsEligibility() {
        Task { @MainActor in
            let isEnabled = await selfDriventPNEligiblityChecker.checkM1Eligibility()
            if selfDrivenPushNotificationEnabled != isEnabled {
                selfDrivenPushNotificationEnabled = isEnabled
                if let pendingTokenData {
                    self.pendingTokenData = nil
                    registerDeviceToken(with: pendingTokenData)
                }
            }
        }
    }

    /// Registers an APNS DeviceToken in the WordPress.com backend.
    ///
    func registerDotcomDevice(with deviceToken: String, onCompletion: @escaping (DotcomDevice?, Error?) -> Void) {
        let device = APNSDevice(deviceToken: deviceToken)
        let action = NotificationAction.registerDevice(device: device,
                                                       applicationId: WooConstants.pushApplicationID,
                                                       applicationVersion: Bundle.main.version,
                                                       onCompletion: onCompletion)
        stores.dispatch(action)
    }

    /// Registers the push notification token for all user sites concurrently.
    /// Throws if any site fails to register.
    @MainActor
    func registerSelfDrivenPushNotificationsForAllSites(with deviceToken: String) async throws {
        var allSiteIDs = storageManager.viewStorage.loadAllSites()
            .filter { $0.isWooCommerceActive?.boolValue == true }
            .map(\.siteID)
        if allSiteIDs.isEmpty, let siteID {
            allSiteIDs = [siteID]
        }

        let siteIDsToRegister = allSiteIDs.filter { !registrationState.isSiteRegisteredForWooPNs($0) }
        guard siteIDsToRegister.isNotEmpty else {
            DDLogDebug("📱 All \(allSiteIDs.count) site(s) already registered for push notifications")
            return
        }

        DDLogDebug("📱 Registering push token for \(siteIDsToRegister.count) site(s): \(siteIDsToRegister) " +
                   "(skipping \(allSiteIDs.count - siteIDsToRegister.count) already registered)")

        var failedSiteIDs: [Int64] = []
        await withTaskGroup(of: (Int64, Bool).self) { group in
            for siteID in siteIDsToRegister {
                group.addTask { [weak self] in
                    let succeeded = await self?.registerSelfDrivenPushNotification(with: deviceToken, siteID: siteID) ?? false
                    return (siteID, succeeded)
                }
            }
            for await (siteID, succeeded) in group where !succeeded {
                failedSiteIDs.append(siteID)
            }
        }

        if failedSiteIDs.isNotEmpty {
            throw PushNotificationError.siteRegistrationFailed(siteIDs: failedSiteIDs)
        }
    }

    /// Registers the push notification token for a single site and handles the result.
    /// - Returns: `true` on success, `false` on failure.
    @MainActor
    private func registerSelfDrivenPushNotification(with deviceToken: String, siteID: Int64) async -> Bool {
        DDLogDebug("📱 Requesting push token registration for site \(siteID)")
        do {
            let tokenID = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int64, Error>) in
                registerSelfDrivenPushNotificationFlow(with: deviceToken, siteID: siteID) { result in
                    continuation.resume(with: result)
                }
            }
            DDLogDebug("📱 Push token registration succeeded for site \(siteID): tokenID \(tokenID)")
            analytics.track(.wooPushTokenRegisterSuccess)
            return true
        } catch {
            DDLogDebug("📱 Push token registration failed for site \(siteID): \(error)")
            analytics.track(.wooPushTokenRegisterError, withError: error)
            if case .notFound = error as? NetworkError {
                registrationState.unmarkSiteAsRegisteredForWooPNs(siteID)
            }
            return false
        }
    }

    func registerSelfDrivenPushNotificationFlow(with deviceToken: String,
                                                siteID: Int64,
                                                onCompletion: @escaping (Result<Int64, Error>) -> Void) {
        DDLogInfo("📱 Registering self-driven push notification token for site \(siteID)")

        // Check plugin version before attempting registration
        Task { @MainActor [weak self] in
            guard let self else { return }
            let minimumVersion = WooPluginRequirements.minimumVersion
            let pluginVersionChecker = pluginVersionCheckerFactory.makeChecker(
                siteID: siteID,
                pluginPath: WooPluginRequirements.pluginPath,
                minimumVersion: minimumVersion
            )
            do {
                let result = try await pluginVersionChecker.checkCompatibility()
                if case .incompatible(let currentVersion, _) = result {
                    DDLogError("⛔️ Unable to register self-driven push token: WooCommerce plugin version \(currentVersion) is below required \(minimumVersion)")
                    registrationState.unmarkSiteAsRegisteredForWooPNs(siteID)
                    onCompletion(.failure(PushNotificationError.pluginVersionIncompatible(
                        currentVersion: currentVersion,
                        requiredVersion: minimumVersion
                    )))
                    return
                }
            } catch {
                DDLogError("⛔️ Failed to check plugin version: \(error)")
                // Continue with registration even if version check fails - the server will validate
            }

            // Plugin version is compatible (or check failed), proceed with registration
            performDeviceRegistration(siteID: siteID, deviceToken: deviceToken, onCompletion: onCompletion)
        }
    }

    private func performDeviceRegistration(siteID: Int64, deviceToken: String, onCompletion: @escaping (Result<Int64, Error>) -> Void) {
        let device = APNSDevice(deviceToken: deviceToken)
        let action = NotificationAction.registerDeviceForSelfDrivenPushNotifications(
            siteID: siteID,
            device: device,
            applicationID: WooConstants.pushApplicationID,
            deviceLocale: Locale.current.languageRegionIdentifier ?? Locale.current.identifier,
            appVersion: Bundle.main.version
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let tokenID):
                self.handleSelfDrivenRegistrationSuccess(tokenID: tokenID, siteID: siteID, onCompletion: onCompletion)

            case .failure(let error):
                DDLogError("⛔️ Unable to register self-driven push token for site \(siteID): \(error)")
                onCompletion(.failure(error))
            }
        }

        stores.dispatch(action)
    }

    func handleSelfDrivenRegistrationSuccess(tokenID: Int64,
                                             siteID: Int64,
                                             onCompletion: @escaping (Result<Int64, Error>) -> Void) {
        registrationState.setWooPushNotificationTokenID(tokenID)
        registrationState.markSiteAsRegisteredForWooPNs(siteID)
        onCompletion(.success(tokenID))
    }

    /// Unregisters the known DeviceID (if any) from the Push Notifications Backend.
    ///
    func unregisterDotcomDeviceIfPossible(onCompletion: @escaping (Error?) -> Void) {
        guard let knownDeviceId = registrationState.deviceID else {
            onCompletion(nil)
            return
        }

        unregisterDotcomDevice(with: knownDeviceId, onCompletion: onCompletion)
    }

    /// Unregisters a given DeviceID from the Push Notifications backend.
    ///
    func unregisterDotcomDevice(with deviceID: String, onCompletion: @escaping (Error?) -> Void) {
        let action = NotificationAction.unregisterDevice(deviceId: deviceID, onCompletion: onCompletion)
        configuration.storesManager.dispatch(action)
    }

    /// Disables mobile push notifications for given site IDs.
    ///
    func disableWPComPushNotificationsIfNeeded(siteIDs: [Int64], deviceID: String?) {
        guard let deviceID, let deviceIDInt = Int64(deviceID),
              siteIDs.isNotEmpty,
              !configuration.storesManager.isAuthenticatedWithoutWPCom else {
            return
        }
        let updatedBlogs = siteIDs.map {
            NotificationSettings.Blog(blogID: $0, devices: [
                .init(deviceID: deviceIDInt, newComment: false, storeOrder: false)
            ])
        }
        let siteSettings = NotificationSettings(blogs: updatedBlogs)
        stores.dispatch(AccountAction.updateNotificationSettings(notificationSettings: siteSettings, onCompletion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                analytics.track(.wpcomDeviceDisablePushNotificationsSuccess)
            case .failure(let error):
                analytics.track(.wpcomDeviceDisablePushNotificationsError, withError: error)
            }
        }))
    }

    func unregisterFromWooPushNotificationsIfPossible(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let siteID,
              let tokenID = registrationState.wooPushNotificationToken,
              let tokenIDInt = Int64(tokenID) else {
            return completion(.success(()))
        }
        stores.dispatch(NotificationAction.unregisterFromSelfDrivenPushNotifications(
            siteID: siteID,
            tokenID: tokenIDInt,
            onCompletion: completion
        ))
    }
}


// MARK: - Analytics
//
private extension PushNotificationsManager {

    /// Tracks the specified Notification's Payload.
    ///
    func trackNotification(with userInfo: [AnyHashable: Any]) {
        var properties = [String: Any]()

        if let noteID = userInfo.string(forKey: APNSKey.identifier) {
            properties[AnalyticKey.identifier] = noteID
        }

        if let type = userInfo.string(forKey: APNSKey.type) {
            properties[AnalyticKey.type] = type
        }

        if let theToken = registrationState.deviceToken {
            properties[AnalyticKey.token] = theToken
        }

        if let siteID = siteID,
           let notificationSiteID = userInfo[APNSKey.siteID] as? Int64 {
            properties[AnalyticKey.fromSelectedSite] = siteID == notificationSiteID
        }

        switch applicationState {
        case .inactive:
            analytics.track(.pushNotificationAlertPressed, withProperties: properties)
        default:
            properties[AnalyticKey.appState] = applicationState.rawValue
            analytics.track(.pushNotificationReceived, withProperties: properties)
        }
    }
}


// MARK: - Yosemite Methods
//
private extension PushNotificationsManager {

    /// Synchronizes all of the Notifications. On success this method will always signal `.newData`, and `.noData` on error.
    ///
    @MainActor
    func synchronizeNotifications() async -> UIBackgroundFetchResult {
        await withCheckedContinuation { continuation in
            let action = NotificationAction.synchronizeNotifications { error in
                DDLogInfo("📱 Finished Synchronizing Notifications!")

                let result = (error == nil) ? UIBackgroundFetchResult.newData : .noData
                continuation.resume(returning: result)
            }

            DDLogInfo("📱 Synchronizing Notifications in \(applicationState.description) State...")
            configuration.storesManager.dispatch(action)
        }
    }
}

// MARK: - UNNotificationContent Extension

private extension UNNotificationContent {
    var isRemoteNotification: Bool {
        userInfo[APNSKey.type] != nil
    }
}

// MARK: - App Icon Badge Number

enum AppIconBadgeNumber {
    /// Indicates that there are unread push notifications in Notification Center.
    static let hasUnreadPushNotifications = 1
    /// An unofficial workaround to clear the app icon badge without clearing all push notifications in Notification Center.
    static let clearsBadgeOnly = -1
    /// Clears the app icon badge and potentially all push notifications in Notification Center.
    static let clearsBadgeAndPotentiallyAllPushNotifications = 0
}

// MARK: - Private Types
//

private enum AnalyticKey {
    static let identifier = "push_notification_note_id"
    static let type = "push_notification_type"
    static let token = "push_notification_token"
    static let fromSelectedSite = "is_from_selected_site"
    static let appState = "app_state"
}

private enum PushNotificationError: Error {
    case deviceTokenTimeout
    case missingSiteID
    case siteRegistrationFailed(siteIDs: [Int64])
    case pluginVersionIncompatible(currentVersion: String, requiredVersion: String)
}

private enum PushType {
    static let badgeReset = "badge-reset"
    static let zendesk = "zendesk"
}

private extension PushNotificationsManager {
    enum Localization {
        static let viewInAppNotification = NSLocalizedString("View", comment: "Action title in an in-app notification to view more details.")
    }
}
