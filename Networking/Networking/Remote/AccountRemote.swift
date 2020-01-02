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


    /// Loads the AccountSettings associated with the Credential's authToken.
    /// - Parameters:
    ///   - for: The dotcom user ID - used primarily for persistence not on the actual network call
    ///
    public func loadAccountSettings(for userID: Int64, completion: @escaping (AccountSettings?, Error?) -> Void) {
        let path = "me/settings"
        let parameters = [
            "fields": "tracks_opt_out"
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = AccountSettingsMapper(userID: userID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates the tracks opt out setting for the account associated with the Credential's authToken.
    /// - Parameters:
    ///   - userID: The dotcom user ID - used primarily for persistence not on the actual network call
    ///
    public func updateAccountSettings(for userID: Int64, tracksOptOut: Bool, completion: @escaping (AccountSettings?, Error?) -> Void) {
        let path = "me/settings"
        let parameters = [
            "fields": "tracks_opt_out",
            "tracks_opt_out": String(tracksOptOut)
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        let mapper = AccountSettingsMapper(userID: userID)

        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Loads the Sites collection associated with the WordPress.com User.
    ///
    public func loadSites(completion: @escaping ([Site]?, Error?) -> Void) {
        let path = "me/sites"
        let parameters = [
            "fields": "ID,name,description,URL,options",
            "options": "timezone,is_wpcom_store,woocommerce_is_active"
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SiteListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Loads the site plan for the default site associated with the WordPress.com user.
    ///
    public func loadSitePlan(for siteID: Int64, completion: @escaping (SitePlan?, Error?) -> Void) {
        let path = "sites/\(siteID)"
        let parameters = [
            "fields": "ID,plan"
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SitePlanMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}
