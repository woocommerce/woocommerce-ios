import Foundation
import UserNotifications
import CocoaLumberjack
import AutomatticTracks
import Yosemite


///
///
class PushNotificationsManager {

    ///
    ///
    private let defaults: UserDefaults

    ///
    ///
    private let application: UIApplication

    ///
    ///
    private let userNotificationCenter: UNUserNotificationCenter

    ///
    ///
    private var applicationState: UIApplication.State {
        return application.applicationState
    }

    ///
    ///
    private var deviceToken: String? {
        get {
            return defaults.object(forKey: .deviceToken)
        }
        set {
            defaults.set(newValue, forKey: .deviceToken)
        }
    }

    ///
    ///
    private var deviceID: String? {
        get {
            return defaults.object(forKey: .deviceID)
        }
        set {
            defaults.set(newValue, forKey: .deviceID)
        }
    }


    ///
    ///
    init(defaults: UserDefaults = .standard, application: UIApplication = .shared, userNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.defaults = defaults
        self.application = application
        self.userNotificationCenter = userNotificationCenter
    }
}


// MARK: - Public Methods
//
extension PushNotificationsManager {

    ///
    ///
    func ensureAuthorizationIsRequested() {
        loadAuthorizationStatus { status in
            guard status == .notDetermined else {
                return
            }

            self.requestAuthorization { allowed in
                let stat: WooAnalyticsStat = allowed ? .pushNotificationOSAlertAllowed : .pushNotificationOSAlertDenied
                WooAnalytics.shared.track(stat)
            }

            WooAnalytics.shared.track(.pushNotificationOSAlertShown)
        }
    }


    ///
    ///
    func registerForRemoteNotifications() {
        application.registerForRemoteNotifications()
    }


    ///
    ///
    func unregisterForRemoteNotifications() {
        guard let knownDeviceId = deviceID else {
            return
        }

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
    func registerDeviceToken(with tokenData: Data, defaultStoreID: Int) {
        guard StoresManager.shared.isAuthenticated else {
            return
        }

        ///
        ///
        let newToken = tokenData.hexString

        if deviceToken != newToken {
            DDLogInfo("Device Token Changed! OLD: [\(String(describing: deviceToken))] NEW: [\(newToken)]")
        } else {
            DDLogInfo("Device Token Received: [\(newToken)]")
        }

        ///
        ///
        registerDotcomDevice(with: newToken, defaultStoreID: defaultStoreID) { (device, error) in
            guard let deviceID = device?.deviceID else {
                DDLogError("⛔️ Dotcom Push Notifications Registration Failure: \(error.debugDescription)")
                return
            }

            DDLogVerbose("Successfully registered Device ID \(deviceID) for Push Notifications")
            self.deviceID = deviceID
        }

        deviceToken = newToken
    }


    ///
    ///
    func registrationDidFail(with error: Error) {
        DDLogError("⛔️ Push Notifications Registration Failure: \(error)")
        unregisterForRemoteNotifications()
    }


    ///
    ///
    func handleNotification(_ userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DDLogVerbose("Application State: \(applicationState.rawValue)")
        DDLogVerbose("Push Notification Received: \n\(userInfo)\n")

        // Badge: Update
        if let badgeCountNumber = userInfo[APNSKey.badge] as? Int {
            application.applicationIconBadgeNumber = badgeCountNumber
        }

        // Badge: Reset
        guard userInfo.valueAsString(forKey: APNSKey.type) != PushType.badgeReset else {
            return
        }

        // Analytics
        trackNotification(with: userInfo)

        // Handling!
        let handlers = [ handleInactiveNotification,
                         handleBackgroundNotification ]

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

    ///
    ///
    func handleInactiveNotification(_ userInfo: [AnyHashable: Any], completionHandler: (UIBackgroundFetchResult) -> Void) -> Bool {
        guard applicationState == .inactive else {
            return false
        }

        guard let notificationId = userInfo.valueAsString(forKey: APNSKey.identifier) else {
            return false
        }

        //        WPTabBarController.sharedInstance().showNotificationsTabForNote(withID: notificationId)
        completionHandler(.newData)

        return true
    }


    ///
    ///
    func handleBackgroundNotification(_ userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        guard applicationState == .background else {
            return false
        }

        guard let _ = userInfo.valueAsString(forKey: APNSKey.identifier) else {
            return false
        }

        let action = NotificationAction.synchronizeNotifications { error in
            DDLogInfo("Finished Notifications Background Fetch!")

            let result = (error == nil) ? UIBackgroundFetchResult.newData : .noData
            completionHandler(result)
        }

        DDLogInfo("Running Notifications Background Fetch...")
        StoresManager.shared.dispatch(action)

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
        StoresManager.shared.dispatch(action)
    }


    /// Unregisters a given DeviceID from the Push Notifications backend.
    ///
    func unregisterDotcomDevice(with deviceID: String, onCompletion: @escaping (Error?) -> Void) {
        let action = NotificationAction.unregisterDevice(deviceId: deviceID, onCompletion: onCompletion)
        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Permission Management
//
private extension PushNotificationsManager {

    ///
    ///
    func loadAuthorizationStatus(queue: DispatchQueue = .main, completion: @escaping (_ status: UNAuthorizationStatus) -> Void) {
        userNotificationCenter.getNotificationSettings { settings in
            queue.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    ///
    ///
    func requestAuthorization(queue: DispatchQueue = .main, completion: @escaping (Bool) -> Void) {
        userNotificationCenter.requestAuthorization(options: [.badge, .sound, .alert]) { (allowed, _)  in
            queue.async {
                completion(allowed)
            }
        }
    }
}


// MARK: - Analytics
//
private extension PushNotificationsManager {

    ///
    ///
    func trackNotification(with userInfo: [AnyHashable: Any]) {
        var properties = [String: String]()

        if let noteId = userInfo.valueAsString(forKey: APNSKey.identifier) {
            properties[AnalyticKey.identifier] = String(noteId)
        }

        if let type = userInfo.valueAsString(forKey: APNSKey.type) {
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
