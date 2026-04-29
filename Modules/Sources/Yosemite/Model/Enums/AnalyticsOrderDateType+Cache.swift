import Foundation
import Storage

public extension AnalyticsOrderDateType {
    /// Reads the cached analytics order date type for the given site from local storage.
    /// Returns `nil` when no value has been persisted yet for this site, or when the
    /// stored value can't be mapped to a known case.
    ///
    /// `SettingStoreMethods.retrieveAnalyticsOrderDateType` and
    /// `updateAnalyticsOrderDateType` write the value to `Storage.SiteSetting` on every
    /// successful network call, so callers can use this helper to seed UI state
    /// synchronously on launch and avoid a flash of the backend default while the
    /// network round-trip is in flight.
    static func cachedValue(siteID: Int64, storageManager: StorageManagerType) -> AnalyticsOrderDateType? {
        guard let value = storageManager.viewStorage.loadSiteSetting(siteID: siteID, settingID: cachedSettingID)?.value else {
            return nil
        }
        return AnalyticsOrderDateType(rawValue: value)
    }

    /// Mirrors `SiteSettingsRemote.Constants.analyticsOrderDateTypeSettingID`. Kept in
    /// sync manually because the Networking constant is private to that file.
    private static var cachedSettingID: String { "woocommerce_date_type" }
}
