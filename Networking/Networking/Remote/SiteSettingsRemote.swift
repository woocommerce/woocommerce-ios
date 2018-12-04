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
    public func loadGeneralSettings(for siteID: Int, completion: @escaping ([SiteSetting]?, Error?) -> Void) {
        let path = Constants.generalSettingsPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = SiteSettingsMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension SiteSettingsRemote {
    enum Constants {
        static let generalSettingsPath: String   = "settings/general"
    }
}
