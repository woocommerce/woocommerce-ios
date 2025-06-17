import Foundation
import Storage

public protocol POSEligibilityServiceProtocol {
    func loadPOSTabVisibility(siteID: Int64) -> Bool?
}

public class POSEligibilityService: POSEligibilityServiceProtocol {
    private let siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol

    public convenience init() {
        self.init(siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage()))
    }

    init(siteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol) {
        self.siteSpecificAppSettingsStoreMethods = siteSpecificAppSettingsStoreMethods
    }

    /// Loads the POS tab visibility for a given site.
    /// - Parameters:
    ///   - siteID: The site ID to check visibility for.
    /// - Returns: The cached visibility state.
    public func loadPOSTabVisibility(siteID: Int64) -> Bool? {
        let storeSettings = siteSpecificAppSettingsStoreMethods.getStoreSettings(for: siteID)
        return storeSettings.isPOSTabVisible
    }
}
