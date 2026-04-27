import Foundation
import Networking

public enum SettingError: Error {
    case parseError
}

/// SettingAction: Defines all of the Actions supported by the SettingStore.
///
public enum SettingAction: Action {

    /// Synchronizes the site's general settings
    ///
    case synchronizeGeneralSiteSettings(siteID: Int64, onCompletion: (Error?) -> Void)

    /// Synchronizes the site's product settings
    ///
    case synchronizeProductSiteSettings(siteID: Int64, onCompletion: (Error?) -> Void)

    /// Retrieves the site API details (used to determine the WC version)
    ///
    case retrieveSiteAPI(siteID: Int64, onCompletion: (Result<SiteAPI, Error>) -> Void)

    /// Retrieves the site settings specific of Point of Sale
    ///
    case retrievePointOfSaleSettings(siteID: Int64, onCompletion: (Result<[SiteSetting], Error>) -> Void)

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

    /// Retrieves the information on what are the taxes based on (shop, billing, or shipping address)
    ///
    case retrieveTaxBasedOnSetting(siteID: Int64, onCompletion: (Result<TaxBasedOnSetting, Error>) -> Void)

    /// Checks if a specific feature is enabled in the site WC settings
    ///
    case isFeatureEnabled(siteID: Int64, feature: SiteSettingsFeature, onCompletion: (Result<Bool, Error>) -> Void)

    /// Retrieves the WooCommerce Analytics order date-type setting (`woocommerce_date_type`).
    ///
    case retrieveAnalyticsOrderDateType(siteID: Int64, onCompletion: (Result<AnalyticsOrderDateType, Error>) -> Void)

    /// Updates the WooCommerce Analytics order date-type setting (`woocommerce_date_type`).
    ///
    case updateAnalyticsOrderDateType(siteID: Int64, value: AnalyticsOrderDateType, onCompletion: (Result<AnalyticsOrderDateType, Error>) -> Void)
}
