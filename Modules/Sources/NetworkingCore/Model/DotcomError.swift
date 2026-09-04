import Foundation
import Codegen

/// WordPress.com Request Error
///
public enum DotcomError: Error, Decodable, Equatable, GeneratedFakeable {

    /// Non explicit reason
    ///
    case empty(data: [String: AnyDecodable]? = nil)

    /// Missing Token!
    ///
    case unauthorized(data: [String: AnyDecodable]? = nil)

    /// We're not properly authenticated
    ///
    case invalidToken(data: [String: AnyDecodable]? = nil)

    /// Remote Request Failed
    ///
    case requestFailed(message: String? = nil, data: [String: AnyDecodable]? = nil)

    /// No route was found matching the URL and request method
    ///
    case noRestRoute(data: [String: AnyDecodable]? = nil)

    /// Jetpack is not connected
    ///
    /// This can be caused by an `unknown_token` error from Jetpack
    /// or an `invalid_blog` error from WordPress.com Stats.
    ///
    case jetpackNotConnected(data: [String: AnyDecodable]? = nil)

    /// WordPress.com no longer recognises the site ID sent by the app.
    ///
    /// Caused by stale selected-site state, a Jetpack disconnect, or site deletion.
    /// Every subsequent request for the same site fails the same way until the
    /// selected site is reset.
    ///
    case unknownBlog(data: [String: AnyDecodable]? = nil)

    /// Signature verification failed on the merchant's WordPress site.
    ///
    /// Jetpack signs the requests it relays to the site; when the site rejects that signature it
    /// answers with `rest_invalid_signature`. The cause is always server side — a broken Jetpack
    /// connection, a security plugin, or an outdated Jetpack — so the app cannot recover by retrying.
    ///
    case invalidSignature(data: [String: AnyDecodable]? = nil)

    /// Unknown: Represents an unmapped remote error. Capisce?
    ///
    case unknown(code: String, message: String?, data: [String: AnyDecodable]?)

    /// Stats error cases - API documentation of possible errors:
    /// https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/stats/
    /// Note: when the cases get large, consider refactoring them into a separate error enum that conforms to a Dotcom error protocol

    /// No permission to view site stats
    case noStatsPermission(data: [String: AnyDecodable]? = nil)

    /// Jetpack site stats module disabled
    case statsModuleDisabled(data: [String: AnyDecodable]? = nil)

    /// The requested resourced does not exist remotely
    case resourceDoesNotExist(data: [String: AnyDecodable]? = nil)

    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        /// The identifier is read before anything else so that a body without one costs nothing. A
        /// successful tunneled response carries the whole payload under `data`, and decoding it up here
        /// would build a dictionary out of every product and order the app fetches, only to throw it away.
        ///
        guard let error = try container.decodeIfPresent(String.self, forKey: .error) else {
            /// WordPress REST errors name the identifier `code` rather than `error`. Only the invalid
            /// signature identifier is read from it, on purpose: mapping every `code`-shaped body here
            /// would start throwing `DotcomError` for responses this validator has always ignored.
            ///
            guard try container.decodeIfPresent(String.self, forKey: .code) == Constants.invalidSignature else {
                throw DecodingError.keyNotFound(CodingKeys.error, .init(codingPath: container.codingPath,
                                                                       debugDescription: "No WordPress.com error identifier found"))
            }
            let data = try container.decodeIfPresent([String: AnyDecodable].self, forKey: .data)
            self = .invalidSignature(data: data)
            return
        }

        let message = try container.decodeIfPresent(String.self, forKey: .message)
        let data = try container.decodeIfPresent([String: AnyDecodable].self, forKey: .data)

        switch error {
        case Constants.invalidToken:
            self = .invalidToken(data: data)
        case Constants.requestFailed:
            self = .requestFailed(message: message, data: data)
        case Constants.unauthorized where message == ErrorMessages.noStatsPermission:
            self = .noStatsPermission(data: data)
        case Constants.unauthorized:
            self = .unauthorized(data: data)
        case Constants.noRestRoute:
            self = .noRestRoute(data: data)
        case Constants.invalidBlog where message == ErrorMessages.statsModuleDisabled:
            self = .statsModuleDisabled(data: data)
        case Constants.restTermInvalid where message == ErrorMessages.resourceDoesNotExist:
            self = .resourceDoesNotExist(data: data)
        case Constants.unknownToken,
            Constants.invalidBlog where message == ErrorMessages.jetpackNotConnected:
            self = .jetpackNotConnected(data: data)
        case Constants.unknownBlog:
            self = .unknownBlog(data: data)
        case Constants.invalidSignature:
            self = .invalidSignature(data: data)
        default:
            self = .unknown(code: error, message: message, data: data)
        }
    }

    /// Constants for Possible Error Identifiers
    ///
    private enum Constants {
        static let unauthorized     = "unauthorized"
        static let invalidBlog      = "invalid_blog"
        static let invalidToken     = "invalid_token"
        static let requestFailed    = "http_request_failed"
        static let noRestRoute      = "rest_no_route"
        static let restTermInvalid  = "woocommerce_rest_term_invalid"
        static let unknownToken     = "unknown_token"
        static let unknownBlog      = "unknown_blog"
        static let invalidSignature = "rest_invalid_signature"
    }

    /// The identifier Jetpack returns when signature verification fails, exposed so the networking layer
    /// can key on the same string when the error reaches it as a status code failure rather than as a
    /// parsed `DotcomError`.
    ///
    static let invalidSignatureCode = Constants.invalidSignature

    /// Coding Keys
    ///
    private enum CodingKeys: String, CodingKey {
        case error
        case code
        case message
        case data
    }

    /// Possible Error Messages
    ///
    private enum ErrorMessages {
        static let statsModuleDisabled = "This blog does not have the Stats module enabled"
        static let noStatsPermission = "user cannot view stats"
        static let resourceDoesNotExist = "Resource does not exist."
        static let jetpackNotConnected = "This blog does not have Jetpack connected"
    }
}


// MARK: - CustomStringConvertible Conformance
//
extension DotcomError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .empty:
            return NSLocalizedString("Dotcom Response Empty", comment: "WordPress.com Error thrown when the response body is empty")
        case .invalidToken:
            return NSLocalizedString("Dotcom Token Invalid", comment: "WordPress.com Invalid Token")
        case .requestFailed:
            return NSLocalizedString("Dotcom Request Failed", comment: "WordPress.com Request Failure")
        case .unauthorized:
            return NSLocalizedString("Dotcom Missing Token", comment: "WordPress.com Missing Token")
        case .noRestRoute:
            return NSLocalizedString("Dotcom Invalid REST Route", comment: "WordPress.com error thrown when the the request REST API url is invalid.")
        case .noStatsPermission:
            return NSLocalizedString("Dotcom No Stats Permission", comment: "WordPress.com error thrown when the user has no permission to view site stats.")
        case .statsModuleDisabled:
            return NSLocalizedString("Dotcom Stats Module Disabled", comment: "WordPress.com error thrown when the Jetpack site stats module is disabled.")
        case .resourceDoesNotExist:
            return NSLocalizedString("Dotcom Resource does not exist", comment: "WordPress.com error thrown when a requested resource does not exist remotely.")
        case .jetpackNotConnected:
            return NSLocalizedString("Jetpack Not Connected", comment: "WordPress.com error thrown when Jetpack is not connected.")
        case .unknownBlog:
            return NSLocalizedString("Dotcom Unknown Blog", comment: "WordPress.com error thrown when the site ID is no longer recognized.")
        case .invalidSignature:
            return NSLocalizedString("dotcomError.invalidSignature.description",
                                     value: "Dotcom Invalid Signature",
                                     comment: "WordPress.com error thrown when the store rejects the signature of a Jetpack request.")
        case .unknown(let code, let message, _):
            let theMessage = message ?? String()
            let messageFormat = NSLocalizedString(
                "Dotcom Error: [%1$@] %2$@",
                comment: "WordPress.com (unmapped!) error. Parameters: %1$@ - code, %2$@ - message"
            )
            return String.localizedStringWithFormat(messageFormat, code, theMessage)
        }
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: DotcomError, rhs: DotcomError) -> Bool {
    switch (lhs, rhs) {
    case (.empty, .empty),
        (.unauthorized, .unauthorized),
        (.invalidToken, .invalidToken),
        (.requestFailed, .requestFailed),
        (.noRestRoute, .noRestRoute),
        (.jetpackNotConnected, .jetpackNotConnected),
        (.unknownBlog, .unknownBlog),
        (.invalidSignature, .invalidSignature),
        (.noStatsPermission, .noStatsPermission),
        (.statsModuleDisabled, .statsModuleDisabled),
        (.resourceDoesNotExist, .resourceDoesNotExist):
        return true
    case let (.unknown(codeLHS, _, _), .unknown(codeRHS, _, _)):
        return codeLHS == codeRHS
    default:
        return false
    }
}
