import Foundation
import Alamofire


/// Account: Remote Endpoints
///
public class AccountRemote: Remote {

    /// Loads the Account Details associated with the Credential's authToken.
    ///
    public func loadAccount(completion: @escaping (Account?, Error?) -> Void) {
        let path = "me"
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path)
        let mapper = AccountMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    public func loadAccountSettings(completion: @escaping (AccountSettings?, Error?) -> Void) {
        let path = "me/settings"
        let parameters = [
            "fields": "tracks_opt_out"
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = AccountSettingsMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Loads the Sites collection associated with the WordPress.com User.
    ///
    public func loadSites(completion: @escaping ([Site]?, Error?) -> Void) {
        let path = "me/sites"
        let parameters = [
            "fields": "ID,name,description,URL,options"
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SiteListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Loads the site plan for the default site associated with the WordPress.com user.
    ///
    public func loadSitePlan(for siteID: Int, completion: @escaping (SitePlan?, Error?) -> Void) {
        let path = "sites/\(siteID)"
        let parameters = [
            "fields": "ID,plan"
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SitePlanMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}
