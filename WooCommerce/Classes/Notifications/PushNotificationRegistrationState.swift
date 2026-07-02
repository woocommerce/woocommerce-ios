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

    /// Per-site Woo push token record IDs — unregistering a site requires that site's own record ID.
    /// Stored as `[String: String]` because plists don't support `Int64` keys.
    private(set) var wooPushNotificationTokensBySite: [Int64: Int64] {
        get {
            guard let stored = defaults.dictionary(forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNotificationTokensBySite)
                    as? [String: String] else {
                return [:]
            }
            return stored.reduce(into: [:]) { result, entry in
                if let siteID = Int64(entry.key), let tokenID = Int64(entry.value) {
                    result[siteID] = tokenID
                }
            }
        }
        set {
            let stored = newValue.reduce(into: [String: String]()) { result, entry in
                result["\(entry.key)"] = "\(entry.value)"
            }
            defaults.set(stored, forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNotificationTokensBySite)
        }
    }

    func wooPushNotificationTokenID(for siteID: Int64) -> Int64? {
        wooPushNotificationTokensBySite[siteID]
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

    func setWooPushNotificationTokenID(_ tokenID: Int64, for siteID: Int64) {
        wooPushNotificationTokensBySite[siteID] = tokenID
    }

    func removeWooPushNotificationTokenID(for siteID: Int64) {
        wooPushNotificationTokensBySite[siteID] = nil
    }

    /// One-time migration of the legacy single token record ID into the per-site map. The legacy
    /// owner is unknowable with multiple registered sites, so it is paired with the only registered
    /// site, else the selected one, else dropped.
    func migrateLegacyWooPushNotificationTokenIfNeeded(selectedSiteID: Int64?) {
        guard let legacyToken = defaults.string(forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNotificationToken) else {
            return
        }
        defaults.removeObject(forKey: PushNotificationSharedConstants.UserDefaultsKeys.wooPushNotificationToken)

        guard wooPushNotificationTokensBySite.isEmpty, let tokenID = Int64(legacyToken) else {
            return
        }
        let registeredSites = siteIDsRegisteredForWooPNs
        if registeredSites.count == 1, let onlySite = registeredSites.first {
            wooPushNotificationTokensBySite[onlySite] = tokenID
        } else if let selectedSiteID, registeredSites.contains(selectedSiteID) {
            wooPushNotificationTokensBySite[selectedSiteID] = tokenID
        }
        // No registered sites: orphan token, dropped with the legacy key above.
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

/// WPCom push notification suppression
extension PushNotificationRegistrationState {
    /// Returns `true` when the notification should be suppressed because
    /// the site already receives Woo-driven push notifications.
    ///
    /// Both `blog` (site ID) and `note_id` must be present in `userInfo`
    /// and the site must be registered for Woo push notifications.
    func shouldSuppressWPComNotification(userInfo: [AnyHashable: Any]) -> Bool {
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
        wooPushNotificationTokensBySite = [:]
        siteIDsRegisteredForWooPNs = []
    }

    /// Clears a single site's Woo registration (local token record + registered mark).
    func clearWooRegistration(for siteID: Int64) {
        removeWooPushNotificationTokenID(for: siteID)
        unmarkSiteAsRegisteredForWooPNs(siteID)
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
