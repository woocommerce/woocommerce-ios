import Foundation
import Storage

public extension AnalyticsImportUpdateMode {
    /// Reads the cached analytics import update mode for the given site from local storage.
    /// Returns `nil` when no value has been persisted yet for this site, or when the stored value
    /// can't be mapped to a known mode.
    static func cachedValue(siteID: Int64, storageManager: StorageManagerType) -> AnalyticsImportUpdateMode? {
        guard let value = storageManager.viewStorage.loadSiteSetting(siteID: siteID, settingID: cachedSettingID)?.value else {
            return nil
        }
        return AnalyticsImportUpdateMode(backendValue: value)
    }

    /// Mirrors `SiteSettingsRemote.Constants.analyticsScheduledImportSettingID`. Kept in
    /// sync manually because the Networking constant is private to that file.
    private static var cachedSettingID: String { "woocommerce_analytics_scheduled_import" }
}
