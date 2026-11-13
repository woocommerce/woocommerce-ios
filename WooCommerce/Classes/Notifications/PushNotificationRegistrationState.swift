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
        setWooPushNextCheck(nil, for: siteID)
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

    /// Site IDs from the last successful WordPress.com `/me/sites` synchronization.
    ///
    /// `nil` means no successful synchronization is available. An empty array means that the
    /// synchronization returned no connected sites.
    var connectedSiteIDs: [Int64]? {
        guard let storedSiteIDsString = defaults.string(forKey: PushNotificationSharedConstants.UserDefaultsKeys.connectedSiteIDs) else {
            return nil
        }
        return storedSiteIDsString
            .components(separatedBy: ",")
            .compactMap { Int64($0) }
    }

    func updateConnectedSiteIDs(_ siteIDs: [Int64]) {
        defaults.set(siteIDs.map { "\($0)" }.joined(separator: ","),
                     forKey: PushNotificationSharedConstants.UserDefaultsKeys.connectedSiteIDs)
    }

    func clearConnectedSiteIDs() { defaults.removeObject(forKey: PushNotificationSharedConstants.UserDefaultsKeys.connectedSiteIDs) }

    /// When each site should next be checked for Woo push registration.
    func wooPushNextCheck(for siteID: Int64) -> Date? {
        wooPushNextCheckDates[String(siteID)]
    }

    func setWooPushNextCheck(_ date: Date?, for siteID: Int64) {
        var dates = wooPushNextCheckDates
        if let date {
            dates[String(siteID)] = date
        } else {
            dates.removeValue(forKey: String(siteID))
        }
        defaults.set(dates, forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNextCheckDates)
    }

    func clearWooPushNextChecks() {
        defaults.removeObject(forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNextCheckDates)
    }
}

/// Push notification suppression
extension PushNotificationRegistrationState {
    /// Returns `true` when a remote site notification should be suppressed.
    ///
    /// A successful WordPress.com site synchronization suppresses both Woo-driven and WPCom
    /// notifications for omitted sites. For connected sites, the existing WPCom/Woo deduplication
    /// remains in place.
    func shouldSuppressNotification(userInfo: [AnyHashable: Any]) -> Bool {
        shouldSuppressDisconnectedSiteNotification(userInfo: userInfo) || shouldSuppressWPComDuplicateNotification(userInfo: userInfo)
    }

    /// Returns `true` when the last successful site synchronization omitted the notification's site.
    /// This is deliberately separate from WPCom/Woo deduplication so notification taps retain
    /// their established behavior for connected sites.
    func shouldSuppressDisconnectedSiteNotification(userInfo: [AnyHashable: Any]) -> Bool {
        guard let siteID = userInfo.integer(forKey: "blog") else {
            return false
        }
        guard let connectedSiteIDs else {
            return false
        }
        return connectedSiteIDs.contains(siteID) == false
    }

    /// Returns `true` when a WPCom notification duplicates a Woo-driven registration.
    private func shouldSuppressWPComDuplicateNotification(userInfo: [AnyHashable: Any]) -> Bool {
        guard let siteID = userInfo["blog"] as? Int64,
              let _ = userInfo["note_id"] as? Int64 else {
            return false
        }
        return isSiteRegisteredForWooPNs(siteID)
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
    var wooPushNextCheckDates: [String: Date] {
        defaults.dictionary(forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNextCheckDates) as? [String: Date] ?? [:]
    }

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
