import Combine
import Foundation

/// Protocol for `AccountRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol AccountRemoteProtocol {
    func loadAccount(completion: @escaping (Result<Account, Error>) -> Void)
    func loadAccountSettings(for userID: Int64, completion: @escaping (Result<AccountSettings, Error>) -> Void)
    func updateAccountSettings(for userID: Int64, tracksOptOut: Bool, completion: @escaping (Result<AccountSettings, Error>) -> Void)
    func loadSites() -> AnyPublisher<Result<[Site], Error>, Never>
    func checkIfWooCommerceIsActive(for siteID: Int64) -> AnyPublisher<Result<Bool, Error>, Never>
    func fetchWordPressSiteSettings(for siteID: Int64) -> AnyPublisher<Result<WordPressSiteSettings, Error>, Never>
    func loadSitePlan(for siteID: Int64, completion: @escaping (Result<SitePlan, Error>) -> Void)
}

/// Account: Remote Endpoints
///
public class AccountRemote: Remote, AccountRemoteProtocol {

    /// Loads the Account Details associated with the Credential's authToken.
    ///
    public func loadAccount(completion: @escaping (Result<Account, Error>) -> Void) {
        let path = "me"
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path)
        let mapper = AccountMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Loads the AccountSettings associated with the Credential's authToken.
    /// - Parameters:
    ///   - for: The dotcom user ID - used primarily for persistence not on the actual network call
    ///
    public func loadAccountSettings(for userID: Int64, completion: @escaping (Result<AccountSettings, Error>) -> Void) {
        let path = "me/settings"
        let parameters = [
            "fields": "tracks_opt_out,first_name,last_name"
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = AccountSettingsMapper(userID: userID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates the tracks opt out setting for the account associated with the Credential's authToken.
    /// - Parameters:
    ///   - userID: The dotcom user ID - used primarily for persistence not on the actual network call
    ///
    public func updateAccountSettings(for userID: Int64, tracksOptOut: Bool, completion: @escaping (Result<AccountSettings, Error>) -> Void) {
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
    public func loadSites() -> AnyPublisher<Result<[Site], Error>, Never> {
        let path = "me/sites"
        let parameters = [
            "fields": "ID,name,description,URL,options,jetpack,jetpack_connection",
            "options": "timezone,is_wpcom_store,woocommerce_is_active,gmt_offset"
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SiteListMapper()

        return enqueue(request, mapper: mapper)
    }

    /// Checks the WooCommerce site settings endpoint to confirm if the WooCommerce plugin is available or not.
    /// We pass an empty `_fields` just to reduce the response payload size, as we don't care about the contents.
    /// The current use case is for a workaround for Jetpack Connection Package sites.
    /// - Parameter siteID: Site for which we will fetch the site settings.
    /// - Returns: A publisher that emits a boolean which indicates if WooCommerce plugin is active.
    public func checkIfWooCommerceIsActive(for siteID: Int64) -> AnyPublisher<Result<Bool, Error>, Never> {
        let parameters = ["_fields": ""]
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: Constants.wooCommerceSiteSettingsPath, parameters: parameters)
        let mapper = WooCommerceAvailabilityMapper()
        return enqueue(request, mapper: mapper)
    }

    /// Fetches WordPress site settings for site metadata (e.g. name, description, URL).
    /// The current use case is for a workaround for Jetpack Connection Package sites.
    /// - Parameter siteID: Site for which we will fetch the site settings.
    /// - Returns: A publisher that emits the WordPress site settings.
    public func fetchWordPressSiteSettings(for siteID: Int64) -> AnyPublisher<Result<WordPressSiteSettings, Error>, Never> {
        let path = "sites/\(siteID)/settings"
        let request = DotcomRequest(wordpressApiVersion: .wpMark2, method: .get, path: path, parameters: nil)
        let mapper = WordPressSiteSettingsMapper()
        return enqueue(request, mapper: mapper)
    }

    /// Loads the site plan for the default site associated with the WordPress.com user.
    ///
    public func loadSitePlan(for siteID: Int64, completion: @escaping (Result<SitePlan, Error>) -> Void) {
        let path = "sites/\(siteID)"
        let parameters = [
            "fields": "ID,plan"
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SitePlanMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants
//
private extension AccountRemote {
    enum Constants {
        static let wooCommerceSiteSettingsPath: String = "settings"
    }
}
