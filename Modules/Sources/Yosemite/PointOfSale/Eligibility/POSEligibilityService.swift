import Foundation
import Storage

/// Protocol defining the interface for POS (Point of Sale) eligibility services.
/// This protocol provides methods to check and manage POS tab visibility.
public protocol POSEligibilityServiceProtocol {
    /// Loads the cached POS tab visibility state for a specific site.
    /// - Parameter siteID: The ID of the site to check visibility for.
    /// - Returns: The cached visibility state as a boolean, or nil if no cached value exists.
    func loadCachedPOSTabVisibility(siteID: Int64) -> Bool?

    /// Caches the POS tab visibility state for a specific site.
    /// - Parameters:
    ///   - siteID: The ID of the site to set visibility for.
    ///   - isVisible: The visibility state to set.
    func cachePOSTabVisibility(siteID: Int64, isVisible: Bool)

    /// Loads the last definite POS entry eligibility result recorded from an online check.
    /// - Parameter siteID: The ID of the site to check eligibility for.
    /// - Returns: The last known eligibility, or nil if no definite result has been recorded.
    func loadLastKnownPOSEligibility(siteID: Int64) -> Bool?

    /// Caches a definite POS entry eligibility result from an online check.
    /// - Parameters:
    ///   - siteID: The ID of the site to record eligibility for.
    ///   - isEligible: The definite eligibility result.
    func cacheLastKnownPOSEligibility(siteID: Int64, isEligible: Bool)
}

public class POSEligibilityService: POSEligibilityServiceProtocol {
    private let siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol

    public convenience init() {
        self.init(siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage()))
    }

    init(siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol) {
        self.siteSpecificAppSettingsStoreMethods = siteSpecificAppSettingsStoreMethods
    }

    /// Loads the cached POS tab visibility for a given site.
    /// - Parameters:
    ///   - siteID: The site ID to check visibility for.
    /// - Returns: The cached visibility state.
    public func loadCachedPOSTabVisibility(siteID: Int64) -> Bool? {
        let storeSettings = siteSpecificAppSettingsStoreMethods.getStoreSettings(for: siteID)
        return storeSettings.isPOSTabVisible
    }

    /// Caches the POS tab visibility for a given site.
    /// - Parameters:
    ///   - siteID: The site ID to set visibility for.
    ///   - isVisible: The visibility state to set.
    public func cachePOSTabVisibility(siteID: Int64, isVisible: Bool) {
        let storeSettings = siteSpecificAppSettingsStoreMethods.getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(isPOSTabVisible: isVisible)
        siteSpecificAppSettingsStoreMethods.setStoreSettings(settings: updatedSettings, for: siteID, onCompletion: nil)
    }

    /// Loads the last definite POS entry eligibility result for a given site.
    /// - Parameter siteID: The site ID to check eligibility for.
    /// - Returns: The last known eligibility, or nil if no definite result has been recorded.
    public func loadLastKnownPOSEligibility(siteID: Int64) -> Bool? {
        let storeSettings = siteSpecificAppSettingsStoreMethods.getStoreSettings(for: siteID)
        return storeSettings.lastKnownPOSEligibility
    }

    /// Caches a definite POS entry eligibility result for a given site.
    /// - Parameters:
    ///   - siteID: The site ID to record eligibility for.
    ///   - isEligible: The definite eligibility result.
    public func cacheLastKnownPOSEligibility(siteID: Int64, isEligible: Bool) {
        let storeSettings = siteSpecificAppSettingsStoreMethods.getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastKnownPOSEligibility: isEligible)
        siteSpecificAppSettingsStoreMethods.setStoreSettings(settings: updatedSettings, for: siteID, onCompletion: nil)
    }
}
