import Foundation
import Alamofire


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
}


// MARK: - Constants!
//
private extension SiteSettingsRemote {
    enum Constants {
        static let siteSettingsPath: String       = "settings/"
        static let generalSettingsGroup: String   = "general"
        static let productSettingsGroup: String   = "products"
    }
}
