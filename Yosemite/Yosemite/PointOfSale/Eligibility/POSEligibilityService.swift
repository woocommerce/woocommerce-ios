import Foundation
import Storage

public protocol POSEligibilityServiceProtocol {
    func loadPOSTabVisibility(siteID: Int64, currentDate: Date) -> Bool?
}

public class POSEligibilityService: POSEligibilityServiceProtocol {
    private let siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol

    public convenience init() {
        self.init(siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage()))
    }

    init(siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol) {
        self.siteSpecificAppSettingsStoreMethods = siteSpecificAppSettingsStoreMethods
    }

    /// Loads the POS tab visibility for a given site and current date.
    /// Returns nil if there's no last check date or if it's older than 3 days.
    /// - Parameters:
    ///   - siteID: The site ID to check visibility for.
    ///   - currentDate: The current date to compare against the last check date.
    /// - Returns: The visibility state if available and recent, nil otherwise.
    public func loadPOSTabVisibility(siteID: Int64, currentDate: Date) -> Bool? {
        let storeSettings = siteSpecificAppSettingsStoreMethods.getStoreSettings(for: siteID)

        // If there's no last check date or it's older than 3 days, nil is returned.
        guard let lastCheckDate = storeSettings.lastPOSTabVisibilityCheckDate else {
            return nil
        }

        let threeDaysInSeconds: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds.
        let timeSinceLastCheck = currentDate.timeIntervalSince(lastCheckDate)
        if timeSinceLastCheck >= threeDaysInSeconds {
            return nil
        }
        return storeSettings.isPOSTabVisible
    }
}
