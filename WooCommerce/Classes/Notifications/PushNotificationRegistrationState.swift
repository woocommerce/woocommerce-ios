import Combine
import Foundation

final class PushNotificationRegistrationState {
    private let defaults: UserDefaults
    private let log: ((String) -> Void)?
    private let siteIDsRegisteredForWooPNsSubject: CurrentValueSubject<[Int64]?, Never>

    init(defaults: UserDefaults, log: ((String) -> Void)? = nil) {
        self.defaults = defaults
        self.log = log

        let storedSiteIDsString = defaults.string(
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        )

        let storedSiteIDs = storedSiteIDsString?
            .components(separatedBy: ",")
            .compactMap { Int64($0) }

        siteIDsRegisteredForWooPNsSubject = CurrentValueSubject(storedSiteIDs)
    }

    /// Apple's Push Notifications DeviceToken
    var deviceToken: String? {
        get {
            defaults.string(forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken)
        }
        set {
            defaults.set(newValue, forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceToken)
        }
    }

    /// WordPress.com Device Identifier
    var deviceID: String? {
        get {
            defaults.string(forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceID)
        }
        set {
            defaults.set(newValue, forKey: PushNotificationSharedConstants.UserDefaultsKeys.deviceID)
        }
    }

    /// Self driven push notification token
    var wooPushNotificationToken: String? {
        get {
            defaults.string(forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNotificationToken)
        }
        set {
            defaults.set(newValue, forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNotificationToken)
        }
    }

    /// The last resolved value of the self-driven push notifications feature flag.
    ///
    /// Persisted to the app-group defaults so the `NotificationServiceExtension` (a separate
    /// process, which can't resolve the flag itself) can read it to decide suppression.
    /// `nil` means it hasn't been resolved yet on this install.
    var selfDrivenPushEnabled: Bool? {
        get {
            defaults.object(forKey: PushNotificationSharedConstants.UserDefaultsKeys.selfDrivenPushEnabled) as? Bool
        }
        set {
            defaults.set(newValue, forKey: PushNotificationSharedConstants.UserDefaultsKeys.selfDrivenPushEnabled)
        }
    }

    /// Site IDs registered to Woo PN system, separated by commas
    private(set) var siteIDsRegisteredForWooPNs: [Int64] {
        get {
            siteIDsRegisteredForWooPNsSubject.value ?? []
        }
        set {
            updateSiteIDsRegisteredForWooPNs(newValue)
        }
    }

    var siteIDsRegisteredForWooPNsPublisher: AnyPublisher<[Int64], Never> {
        siteIDsRegisteredForWooPNsSubject
            .map { $0 ?? [] }
            .eraseToAnyPublisher()
    }

    var hasStoredSiteIDsRegisteredForWooPNs: Bool {
        siteIDsRegisteredForWooPNsSubject.value != nil
    }

    func isSiteRegisteredForWooPNs(_ siteID: Int64) -> Bool {
        siteIDsRegisteredForWooPNs.contains(siteID)
    }

    func markSiteAsRegisteredForWooPNs(_ siteID: Int64) {
        guard isSiteRegisteredForWooPNs(siteID) == false else {
            return
        }
        var updatedIDs = siteIDsRegisteredForWooPNs
        updatedIDs.append(siteID)
        siteIDsRegisteredForWooPNs = updatedIDs
    }

    func unmarkSiteAsRegisteredForWooPNs(_ siteID: Int64) {
        let updatedIDs = siteIDsRegisteredForWooPNs.filter { $0 != siteID }
        guard updatedIDs.count != siteIDsRegisteredForWooPNs.count else {
            instantiateRegisteredSiteIDsCollectionIfAbsent()
            return
        }
        siteIDsRegisteredForWooPNs = updatedIDs
    }

    func setWooPushNotificationTokenID(_ tokenID: Int64) {
        wooPushNotificationToken = "\(tokenID)"
    }

    func applyNewDeviceToken(_ newToken: String) {
        if let existingDeviceToken = deviceToken, existingDeviceToken != newToken {
            log?("📱 Device Token Changed! OLD: [\(existingDeviceToken)] NEW: [\(newToken)]")
        } else {
            log?("📱 Device Token Received: [\(newToken)]")
        }

        deviceToken = newToken
    }
}

/// Push notification suppression
extension PushNotificationRegistrationState {
    /// Returns `true` when the notification should be suppressed to avoid a duplicate, based on
    /// which system (Woo-driven or WPCom) is the active source for the site.
    ///
    /// - WPCom notification (has `note_id`): suppressed while self-driven push is active for the
    ///   site — i.e. the FF hasn't been turned off (`!= false`) and the site is Woo-registered.
    /// - Woo-driven notification (no `note_id`, a Woo store `type`): suppressed only once we've
    ///   fallen back to WPCom (FF explicitly `false`) **and** the site's Woo registration has been
    ///   torn down (`!isSiteRegisteredForWooPNs`). Gating on the teardown — not just `FF == false` —
    ///   avoids a blackout window: while the WPCom re-enable is still pending or failed, we keep
    ///   showing the Woo push rather than suppressing it before WPCom is confirmed back on.
    ///
    /// Nil (`selfDrivenPushEnabled == nil`, not yet resolved) preserves legacy behavior: WPCom is
    /// suppressed for Woo-registered sites, and Woo is never suppressed.
    func shouldSuppress(userInfo: [AnyHashable: Any]) -> Bool {
        guard let siteID = int64Value(userInfo["blog"]) else {
            return false
        }
        let isWPComNotification = int64Value(userInfo["note_id"]) != nil
        if isWPComNotification {
            return selfDrivenPushEnabled != false && isSiteRegisteredForWooPNs(siteID)
        }
        guard let type = userInfo["type"] as? String,
              PushNotificationSharedConstants.wooDrivenPushTypes.contains(type) else {
            return false
        }
        return selfDrivenPushEnabled == false && !isSiteRegisteredForWooPNs(siteID)
    }

    /// Reads an `Int64` from a push-payload value, tolerating the `Int64` / `NSNumber` / `String`
    /// forms APNS may deliver — mirroring `Dictionary.integer(forKey:)` (used by `PushNotification.from`),
    /// which isn't linked into the NotificationServiceExtension target.
    private func int64Value(_ value: Any?) -> Int64? {
        switch value {
        case let value as Int64:
            return value
        case let value as Int:
            return Int64(value)
        case let value as NSNumber:
            return value.int64Value
        case let value as String:
            return Int64(value)
        default:
            return nil
        }
    }
}

/// Clean-up
extension PushNotificationRegistrationState {
    func clearWooRegistration() {
        wooPushNotificationToken = nil
        siteIDsRegisteredForWooPNs = []
    }

    func clearWPComRegistration() {
        deviceID = nil
        deviceToken = nil
    }
}

private extension PushNotificationRegistrationState {
    func instantiateRegisteredSiteIDsCollectionIfAbsent() {
        if siteIDsRegisteredForWooPNsSubject.value != nil {
            return
        }

        siteIDsRegisteredForWooPNs = []
    }

    func updateSiteIDsRegisteredForWooPNs(_ newValue: [Int64]) {
        if siteIDsRegisteredForWooPNsSubject.value == newValue {
            return
        }

        defaults.set(
            newValue.map { "\($0)" }.joined(separator: ","),
            forKey: PushNotificationSharedConstants.UserDefaultsKeys.siteIDsRegisteredForWooPushNotifications
        )

        siteIDsRegisteredForWooPNsSubject.send(newValue)
    }
}
