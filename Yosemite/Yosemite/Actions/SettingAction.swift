import Foundation
import Networking


/// SettingAction: Defines all of the Actions supported by the SettingStore.
///
public enum SettingAction: Action {

    /// Synchronizes the site's general settings
    ///
    case synchronizeGeneralSiteSettings(siteID: Int64, onCompletion: (Error?) -> Void)

    /// Synchronizes the site's product settings
    ///
    case synchronizeProductSiteSettings(siteID: Int64, onCompletion: (Error?) -> Void)

    /// Synchronizes the site's advanced settings
    ///
    case synchronizeAdvancedSiteSettings(siteID: Int64, onCompletion: (Error?) -> Void)

    /// Retrieves the site API details (used to determine the WC version)
    ///
    case retrieveSiteAPI(siteID: Int64, onCompletion: (Result<SiteAPI, Error>) -> Void)

    /// Retrieves the store payments page path.
    ///
    case getPaymentsPagePath(siteID: Int64, onCompletion: (Result<String, SettingStore.SettingError>) -> Void)

    /// Retrieves the setting for whether coupons are enabled for the specified store
    ///
    case retrieveCouponSetting(siteID: Int64, onCompletion: (Result<Bool, Error>) -> Void)

    /// Enables coupons for the specified store
    ///
    case enableCouponSetting(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)

    /// Retrieves the setting for whether WC Analytics are enabled for the specified store
    ///
    case retrieveAnalyticsSetting(siteID: Int64, onCompletion: (Result<Bool, Error>) -> Void)

    /// Enables WC Analytics for the specified store
    ///
    case enableAnalyticsSetting(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)
}
