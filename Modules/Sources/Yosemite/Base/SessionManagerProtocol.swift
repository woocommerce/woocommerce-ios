import Combine
import Foundation

public protocol SessionManagerProtocol {

    /// Ephemeral: Default Account.
    ///
    var defaultAccount: Account? { get set}

    /// Default AccountID: Returns the last known Account's User ID.
    ///
    var defaultAccountID: Int64? { get }

    /// Default Store Site
    ///
    var defaultSite: Site? { get set }

    /// Publishes default site on change.
    ///
    var defaultSitePublisher: AnyPublisher<Site?, Never> { get }

    /// Default StoreID.
    /// This is in fact the WPCom `siteID`.
    ///
    var defaultStoreID: Int64? { get set }

    /// Unique WooCommerce Store UUID.
    /// Do not conduse with `defaultStoreID` which is in fact the WPCom `siteID`.
    ///
    var defaultStoreUUID: String? { get set }

    /// Roles for the default Store Site.
    ///
    var defaultRoles: [User.Role] { get set }

    /// Cached WooCommerce version for the default store.
    ///
    var cachedWooCommerceVersion: String? { get set }

    /// Publishes default store ID on change.
    ///
    var defaultStoreIDPublisher: AnyPublisher<Int64?, Never> { get }

    /// Anonymous UserID.
    ///
    var anonymousUserID: String? { get }

    /// Default Credentials.
    ///
    var defaultCredentials: Credentials? { get set}

    /// Returns persisted cookie-nonce endpoints only for matching WordPress.org credentials.
    ///
    func cookieNonceAuthenticationEndpoints(for credentials: Credentials) -> CookieNonceAuthenticationEndpoints?

    /// Persists non-secret cookie-nonce endpoints for WordPress.org credentials.
    ///
    func saveCookieNonceAuthenticationEndpoints(_ endpoints: CookieNonceAuthenticationEndpoints,
                                                for credentials: Credentials) throws

    /// Removes cookie-nonce endpoints only when they match the WordPress.org credentials.
    ///
    func removeCookieNonceAuthenticationEndpoints(for credentials: Credentials) throws

    /// Nukes all of the known Session's properties.
    ///
    func reset()

    /// Deletes application password
    ///
    func deleteApplicationPassword(using credentials: Credentials?, locally: Bool)
}

/// Helper methods
public extension SessionManagerProtocol {
    /// Let the session manager figure out the credentials by itself
    func deleteApplicationPassword(locally: Bool) {
        deleteApplicationPassword(using: nil, locally: locally)
    }
}
