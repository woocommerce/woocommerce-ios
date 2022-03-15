import Foundation


/// SiteSettings: Remote Endpoints
///
public class SiteSettingsRemote: Remote {

    /// Retrieves all of the general `SiteSetting`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the general settings.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadGeneralSettings(for siteID: Int64, completion: @escaping ([SiteSetting]?, Error?) -> Void) {
        let path = Constants.siteSettingsPath + Constants.generalSettingsGroup
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = SiteSettingsMapper(siteID: siteID, settingsGroup: SiteSettingGroup.general)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the product `SiteSetting`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the product settings.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadProductSettings(for siteID: Int64, completion: @escaping ([SiteSetting]?, Error?) -> Void) {
        let path = Constants.siteSettingsPath + Constants.productSettingsGroup
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = SiteSettingsMapper(siteID: siteID, settingsGroup: SiteSettingGroup.product)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the advanced `SiteSetting`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the advanced settings.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadAdvancedSettings(for siteID: Int64, completion: @escaping (Result<[SiteSetting], Error>) -> Void) {
        let path = Constants.siteSettingsPath + Constants.advancedSettingsGroup
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = SiteSettingsMapper(siteID: siteID, settingsGroup: SiteSettingGroup.advanced)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieve setting for whether coupons are enabled for a given site
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the coupon setting.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadCouponSetting(for siteID: Int64, completion: @escaping (Result<SiteSetting, Error>) -> Void) {
        let path = Constants.siteSettingsPath + Constants.generalSettingsGroup + "/" + Constants.couponEnabledSettingID
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = SiteSettingMapper(siteID: siteID, settingsGroup: SiteSettingGroup.general)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Update setting for coupon for a given site
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll update the coupon setting.
    ///   - value: New value for the setting.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func updateCouponSetting(for siteID: Int64, value: String, completion: @escaping (Result<SiteSetting, Error>) -> Void) {
        let parameters: [String: Any] = [Constants.valueParameter: value]
        let path = Constants.siteSettingsPath + Constants.generalSettingsGroup + "/" + Constants.couponEnabledSettingID
        let request = JetpackRequest(wooApiVersion: .mark3, method: .put, siteID: siteID, path: path, parameters: parameters)
        let mapper = SiteSettingMapper(siteID: siteID, settingsGroup: SiteSettingGroup.general)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension SiteSettingsRemote {
    enum Constants {
        static let siteSettingsPath: String       = "settings/"
        static let generalSettingsGroup: String   = "general"
        static let productSettingsGroup: String   = "products"
        static let advancedSettingsGroup: String   = "advanced"
        static let couponEnabledSettingID: String = "woocommerce_enable_coupons"
        static let valueParameter: String = "value"
    }
}
