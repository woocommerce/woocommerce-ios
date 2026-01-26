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
    var siteIDsRegisteredForWooPNs: [Int64] {
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
