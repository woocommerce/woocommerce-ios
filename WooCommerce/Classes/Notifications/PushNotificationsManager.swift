import Foundation
import UserNotifications
import CocoaLumberjack
import AutomatticTracks
import Yosemite



/// PushNotificationsManager: Encapsulates all the tasks related to Push Notifications Auth + Registration + Handling.
///
class PushNotificationsManager {

    /// PushNotifications Configuration
    ///
    let configuration: PushNotificationsConfiguration

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


    /// Initializes the PushNotificationsManager.
    ///
    /// - Parameter configuration: PushNotificationsConfiguration Instance that should be used.
    ///
    init(configuration: PushNotificationsConfiguration = .default) {
        self.configuration = configuration
    }
}


// MARK: - Public Methods
//
extension PushNotificationsManager {

    /// Requests Authorization to receive Push Notifications, *only* when the current Status is not determined.
    ///
    /// - Parameter onCompletion: Closure to be executed on completion. Receives a Boolean indicating if we've got Push Permission.
    ///
    func ensureAuthorizationIsRequested(onCompletion: ((Bool) -> Void)? = nil) {
        let nc = configuration.userNotificationsCenter

        nc.loadAuthorizationStatus(queue: .main) { status in
            guard status == .notDetermined else {
                onCompletion?(status == .authorized)
                return
            }

            nc.requestAuthorization(queue: .main) { allowed in
                let stat: WooAnalyticsStat = allowed ? .pushNotificationOSAlertAllowed : .pushNotificationOSAlertDenied
                WooAnalytics.shared.track(stat)

                onCompletion?(allowed)
            }

            WooAnalytics.shared.track(.pushNotificationOSAlertShown)
        }
    }


    /// Registers the Application for Remote Notifgications.
    ///
    func registerForRemoteNotifications() {
        DDLogInfo("Registering for Remote Notifications...")
        configuration.application.registerForRemoteNotifications()
    }


    /// Unregisters the Application from WordPress.com Push Notifications Service.
    ///
    func unregisterForRemoteNotifications() {
        guard let knownDeviceId = deviceID else {
            return
        }

        DDLogInfo("Unregistering from WordPress.com Notifications Service...")
        unregisterDotcomDevice(with: knownDeviceId) { error in
            if let error = error {
                DDLogError("⛔️ Unable to unregister push for Device ID \(knownDeviceId): \(error)")
                return
            }

            DDLogInfo("Successfully unregistered Device ID \(knownDeviceId) for Push Notifications!")
            self.deviceID = nil
            self.deviceToken = nil
        }
    }


    /// Registers the Device Token agains WordPress.com backend, if there's a default account.
    ///
    /// - Parameters:
    ///     - tokenData: APNS's Token Data
    ///     - defaultStoreID: Default WooCommerce Store ID
    ///
    func registerDeviceToken(with tokenData: Data, defaultStoreID: Int) {
        let newToken = tokenData.hexString

        if deviceToken != newToken {
            DDLogInfo("Device Token Changed! OLD: [\(String(describing: deviceToken))] NEW: [\(newToken)]")
        } else {
            DDLogInfo("Device Token Received: [\(newToken)]")
        }

        deviceToken = newToken

        // Register in the Dotcom's Infrastructure
        registerDotcomDevice(with: newToken, defaultStoreID: defaultStoreID) { (device, error) in
            guard let deviceID = device?.deviceID else {
                DDLogError("⛔️ Dotcom Push Notifications Registration Failure: \(error.debugDescription)")
                return
            }

            DDLogVerbose("Successfully registered Device ID \(deviceID) for Push Notifications")
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


    /// Handles a Remote Push Notifican Payload. On completion the `completionHandler` will be executed.
    ///
    func handleNotification(_ userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DDLogVerbose("Application State: \(applicationState.rawValue)")
        DDLogVerbose("Push Notification Received: \n\(userInfo)\n")

        // Badge: Update
        if let badgeCountNumber = userInfo[APNSKey.badge] as? Int {
            configuration.application.applicationIconBadgeNumber = badgeCountNumber
        }

        // Badge: Reset
        guard userInfo.string(forKey: APNSKey.type) != PushType.badgeReset else {
            return
        }

        // Analytics
        trackNotification(with: userInfo)

        // Handling!
        let handlers = [ handleInactiveNotification, handleBackgroundNotification ]

        for handler in handlers {
            if handler(userInfo, completionHandler) {
                break
            }
        }
    }
}


// MARK: - Push Handlers
//
private extension PushNotificationsManager {

    /// Handles a Notification while in Inactive Mode
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    /// - Returns: True when handled. False otherwise
    ///
    func handleInactiveNotification(_ userInfo: [AnyHashable: Any], completionHandler: (UIBackgroundFetchResult) -> Void) -> Bool {
        guard applicationState == .inactive else {
            return false
        }

        guard let notificationId = userInfo.integer(forKey: APNSKey.identifier) else {
            return false
        }

        configuration.application.displayNotificationDetails(for: notificationId)
        completionHandler(.newData)

        return true
    }


    /// Handles a Notification while in Background Mode
    ///
    /// - Parameters:
    ///     - userInfo: The Notification's Payload
    ///     - completionHandler: A callback, to be executed on completion
    ///
    /// - Returns: True when handled. False otherwise
    ///
    func handleBackgroundNotification(_ userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        guard applicationState == .background else {
            return false
        }

        guard let _ = userInfo[APNSKey.identifier] else {
            return false
        }

        let action = NotificationAction.synchronizeNotifications { error in
            DDLogInfo("Finished Notifications Background Fetch!")

            let result = (error == nil) ? UIBackgroundFetchResult.newData : .noData
            completionHandler(result)
        }

        DDLogInfo("Running Notifications Background Fetch...")
        configuration.storesManager.dispatch(action)

        return true
    }
}


// MARK: - Dotcom Device Registration
//
private extension PushNotificationsManager {

    /// Registers an APNS DeviceToken in the WordPress.com backend.
    ///
    func registerDotcomDevice(with deviceToken: String, defaultStoreID: Int, onCompletion: @escaping (DotcomDevice?, Error?) -> Void) {
        let device = APNSDevice(deviceToken: deviceToken)
        let action = NotificationAction.registerDevice(device: device,
                                                       applicationId: WooConstants.pushApplicationID,
                                                       applicationVersion: Bundle.main.version,
                                                       defaultStoreID: defaultStoreID,
                                                       onCompletion: onCompletion)
        configuration.storesManager.dispatch(action)
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
        var properties = [String: String]()

        if let noteId = userInfo.string(forKey: APNSKey.identifier) {
            properties[AnalyticKey.identifier] = noteId
        }

        if let type = userInfo.string(forKey: APNSKey.type) {
            properties[AnalyticKey.type] = type
        }

        if let theToken = deviceToken {
            properties[AnalyticKey.token] = theToken
        }

        let event: WooAnalyticsStat = (applicationState == .background) ? .pushNotificationReceived : .pushNotificationAlertPressed
        WooAnalytics.shared.track(event, withProperties: properties)
    }
}


// MARK: - Private Types
//
private enum APNSKey {
    static let badge = "aps.badge"
    static let identifier = "note_id"
    static let type = "type"
}

private enum AnalyticKey {
    static let identifier = "push_notification_note_id"
    static let type = "push_notification_type"
    static let token = "push_notification_token"
}

private enum PushType {
    static let badgeReset = "badge-reset"
}
