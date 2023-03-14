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
    func loadUsernameSuggestions(from text: String) async throws -> [String]

    /// Creates a WPCOM account with the given email and password.
    /// - Parameters:
    ///   - email: user input email.
    ///   - username: auto-generated username.
    ///   - password: user input password.
    ///   - clientID: WPCOM client ID of the WooCommerce iOS app.
    ///   - clientSecret: WPCOM client secret of the WooCommerce iOS app.
    ///
    /// - Returns: the auth token for the newly created account.
    func createAccount(email: String,
                       username: String,
                       password: String,
                       clientID: String,
                       clientSecret: String) async -> Result<CreateAccountResult, CreateAccountError>

    func closeAccount() async throws
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
            "options": "timezone,is_wpcom_store,woocommerce_is_active,gmt_offset,jetpack_connection_active_plugins,admin_url,login_url,frame_nonce"
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

    public func loadUsernameSuggestions(from text: String) async throws -> [String] {
        let path = Path.usernameSuggestions
        let parameters = [ParameterKey.name: text]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)

        let result: [String: [String]] = try await enqueue(request)
        let suggestions = result["suggestions"] ?? []

        return suggestions
    }

    public func createAccount(email: String,
                              username: String,
                              password: String,
                              clientID: String,
                              clientSecret: String) async -> Result<CreateAccountResult, CreateAccountError> {
        let path = Path.accountCreation
        let parameters: [String: Any] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "signup_flow_name": "mobile-ios",
            "flow": "signup",
            "scheme": "woocommerce",
            "password": password,
            "email": email,
            "username": username,
            // Passing `validate=false` always creates an account (if input data is valid) and sends an email
            // to the user that the account was created successfully.
            // Otherwise, email validation is required before an account is created.
            "validate": false,
            "send_verification_email": true
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        do {
            let result: CreateAccountResult = try await enqueue(request)
            return .success(result)
        } catch {
            guard let dotcomError = error as? DotcomError else {
                return .failure(.unknown(error: error as NSError))
            }
            return .failure(CreateAccountError(dotcomError: dotcomError))
        }
    }

    public func closeAccount() async throws {
        let path = Path.closeAccount
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path)
        return try await enqueue(request)
    }
}

// MARK: - Constants
//
private extension AccountRemote {
    enum Constants {
        static let wooCommerceSiteSettingsPath: String = "settings"
    }

    enum ParameterKey {
        static let name = "name"
    }

    enum Path {
        static let settings = "me/settings"
        static let username = "me/username"
        static let usernameSuggestions = "users/username/suggestions"
        static let accountCreation = "users/new"
        static let closeAccount = "me/account/close"
    }
}

/// Necessary data for account credentials.
public struct CreateAccountResult: Decodable, Equatable {
    public let authToken: String
    public let username: String

    public init(authToken: String, username: String) {
        self.authToken = authToken
        self.username = username
    }

    private enum CodingKeys: String, CodingKey {
        case authToken = "bearer_token"
        case username
    }
}

/// Possible errors from WPCOM account creation.
public enum CreateAccountError: Error, Equatable {
    case emailExists
    case invalidUsername
    case invalidEmail
    case invalidPassword(message: String?)
    case unexpected(error: DotcomError)
    case unknown(error: NSError)

    /// Decodable Initializer.
    ///
    init(dotcomError error: DotcomError) {
        if case let .unknown(code, message) = error {
            switch code {
            case Constants.emailExists:
                self = .emailExists
            case Constants.invalidEmail:
                self = .invalidEmail
            case Constants.invalidPassword:
                self = .invalidPassword(message: message)
            case Constants.invalidUsername, Constants.usernameExists:
                self = .invalidUsername
            default:
                self = .unexpected(error: error)
            }
        } else {
            self = .unexpected(error: error)
        }
    }

    /// Constants for Possible Error Identifiers
    ///
    private enum Constants {
        static let emailExists = "email_exists"
        static let invalidEmail = "email_invalid"
        static let invalidPassword = "password_invalid"
        static let usernameExists = "username_exists"
        static let invalidUsername = "username_invalid"
    }
}
