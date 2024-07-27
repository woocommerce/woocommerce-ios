import Combine
import Experiments
import Foundation
import UserNotifications
import AutomatticTracks
import Yosemite
import protocol WooFoundation.Analytics


/// PushNotificationsManager: Encapsulates all the tasks related to Push Notifications Auth + Registration + Handling.
///
final class PushNotificationsManager: PushNotesManager {

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

    /// Apple's Push Notifications DeviceToken
    ///
    private var deviceToken: String? {
        get {
            return configuration.defaults.object(forKey: .deviceToken)
        }
        set {
            configuration.defaults.set(newValue, forKey: .deviceToken)
        }
    }

    /// WordPress.com Device Identifier
    ///
    private var deviceID: String? {
        get {
            return configuration.defaults.object(forKey: .deviceID)
        }
        set {
            configuration.defaults.set(newValue, forKey: .deviceID)
        }
    }

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    private var stores: StoresManager {
        configuration.storesManager
    }

    private let analytics: Analytics

    /// Initializes the PushNotificationsManager.
    ///
    /// - Parameter configuration: PushNotificationsConfiguration Instance that should be used.
    ///
    init(configuration: PushNotificationsConfiguration = .default,
         analytics: Analytics = ServiceLocator.analytics) {
        self.configuration = configuration
        self.analytics = analytics
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


    /// Unregisters the Application from WordPress.com Push Notifications Service.
    ///
    func unregisterForRemoteNotifications() {
        DDLogInfo("📱 Unregistering For Remote Notifications...")

        unregisterDotcomDeviceIfPossible() { error in
            if let error = error {
                DDLogError("⛔️ Unable to unregister from WordPress.com Push Notifications: \(error)")
                return
            }

            DDLogInfo("📱 Successfully unregistered from WordPress.com Push Notifications!")
            self.deviceID = nil
            self.deviceToken = nil
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
    func registerDeviceToken(with tokenData: Data, defaultStoreID: Int64) {
        let newToken = tokenData.hexString

        if let _ = deviceToken, deviceToken != newToken {
            DDLogInfo("📱 Device Token Changed! OLD: [\(String(describing: deviceToken))] NEW: [\(newToken)]")
        } else {
            DDLogInfo("📱 Device Token Received: [\(newToken)]")
        }

        deviceToken = newToken

        // Register in the Dotcom's Infrastructure
        registerDotcomDevice(with: newToken, defaultStoreID: defaultStoreID) { (device, error) in
            guard let deviceID = device?.deviceID else {
                DDLogError("⛔️ Dotcom Push Notifications Registration Failure: \(error.debugDescription)")
                return
            }

            DDLogVerbose("📱 Successfully registered Device ID \(deviceID) for Push Notifications")
            self.deviceID = deviceID
        }
    }


    /// Handles Push Notifications Registration Errors. This method unregisters the current device from the WordPress.com
    /// Push Service.
    ///
    /// - Parameter error: Error received after attempting to register for Push Notifications.
    ///
    func registrationDidFail(with error: Error) {
        DDLogError("⛔️ Push Notifications Registration Failure: \(error)")
        unregisterForRemoteNotifications()
    }

    /// Handles a Notification while in Foreground Mode. Currently, only remote notifications are handled in the foreground.
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    /// - Returns: True when handled. False otherwise
    ///
    @MainActor
    func handleNotificationInTheForeground(_ notification: UNNotification) async -> UNNotificationPresentationOptions {
        let content = notification.request.content
        guard applicationState == .active, content.isRemoteNotification else {
            // Local notifications are currently not handled when the app is in the foreground.
            return UNNotificationPresentationOptions(rawValue: 0)
        }

        handleRemoteNotificationInAllAppStates(content.userInfo)

        if let foregroundNotification = PushNotification.from(userInfo: content.userInfo) {
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

        return await PushNotificationBackgroundSynchronizer(userInfo: userInfo, stores: configuration.storesManager).sync()
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
    func handleInactiveRemoteNotification(notification: PushNotification) async {
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
            configuration.application.presentNotificationDetails(for: Int64(notification.noteID))
        }
    }
}


// MARK: - Dotcom Device Registration
//
private extension PushNotificationsManager {

    /// Registers an APNS DeviceToken in the WordPress.com backend.
    ///
    func registerDotcomDevice(with deviceToken: String, defaultStoreID: Int64, onCompletion: @escaping (DotcomDevice?, Error?) -> Void) {
        let device = APNSDevice(deviceToken: deviceToken)
        let action = NotificationAction.registerDevice(device: device,
                                                       applicationId: WooConstants.pushApplicationID,
                                                       applicationVersion: Bundle.main.version,
                                                       defaultStoreID: defaultStoreID,
                                                       onCompletion: onCompletion)
        stores.dispatch(action)
    }

    /// Unregisters the known DeviceID (if any) from the Push Notifications Backend.
    ///
    func unregisterDotcomDeviceIfPossible(onCompletion: @escaping (Error?) -> Void) {
        guard let knownDeviceId = deviceID else {
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

        if let theToken = deviceToken {
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
        userInfo[APNSKey.identifier] != nil
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

private enum PushType {
    static let badgeReset = "badge-reset"
    static let zendesk = "zendesk"
}

private extension PushNotificationsManager {
    enum Localization {
        static let viewInAppNotification = NSLocalizedString("View", comment: "Action title in an in-app notification to view more details.")
    }
}
