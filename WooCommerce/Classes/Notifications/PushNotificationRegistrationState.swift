import Foundation

final class PushNotificationRegistrationState {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// Apple's Push Notifications DeviceToken
    var deviceToken: String? {
        get {
            defaults.object(forKey: .deviceToken)
        }
        set {
            defaults.set(newValue, forKey: .deviceToken)
        }
    }

    /// WordPress.com Device Identifier
    var deviceID: String? {
        get {
            defaults.object(forKey: .deviceID)
        }
        set {
            defaults.set(newValue, forKey: .deviceID)
        }
    }

    /// Self driven push notification token
    var wooPushNotificationToken: String? {
        get {
            defaults.object(forKey: .wooPushNotificationToken)
        }
        set {
            defaults.set(newValue, forKey: .wooPushNotificationToken)
        }
    }

    /// Site IDs registered to Woo PN system, separated by commas
    private(set) var siteIDsRegisteredForWooPNs: [Int64] {
        get {
            let ids: String? = defaults.object(forKey: .siteIDsRegisteredForWooPushNotifications)
            return ids?.components(separatedBy: ",")
                .compactMap { Int64($0) } ?? []
        }
        set {
            defaults.set(
                newValue.map { "\($0)" }.joined(separator: ","),
                forKey: .siteIDsRegisteredForWooPushNotifications
            )
        }
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
            DDLogInfo("📱 Device Token Changed! OLD: [\(String(describing: existingDeviceToken))] NEW: [\(newToken)]")
        } else {
            DDLogInfo("📱 Device Token Received: [\(newToken)]")
        }

        deviceToken = newToken
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
        guard defaults.containsObject(forKey: .siteIDsRegisteredForWooPushNotifications) == false else {
            return
        }
        siteIDsRegisteredForWooPNs = []
    }
}

extension UserDefaults {
    @objc dynamic var wooPushNotificationToken: String? {
        string(forKey: Key.wooPushNotificationToken.rawValue)
    }

    @objc dynamic var deviceToken: String? {
        string(forKey: Key.deviceToken.rawValue)
    }

    @objc dynamic var siteIDsRegisteredForWooPushNotifications: [Int64]? {
        string(forKey: Key.siteIDsRegisteredForWooPushNotifications.rawValue)?
            .components(separatedBy: ",")
            .compactMap { Int64($0) }
    }
}
