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
}
