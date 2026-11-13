import Yosemite
import enum NetworkingCore.CookieNonceAuthenticationResponseStage

/// Failure dimensions and sanitized support diagnostics for an unexpected login response.
struct LoginUnexpectedResponseFailure: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    enum Action: String {
        case retry
        case contactSupport = "contact_support"
        case dismiss
    }

    enum LoginFlow: String {
        case siteCredentials = "site_credentials"
        case appPassword = "app_password"
        case storePicker = "store_picker"
    }

    typealias Kind = UnexpectedStoreResponseError.Kind

    enum Step: String {
        case loginPage = "login_page"
        case credentialsSubmission = "credentials_submission"
        case dashboardVerification = "dashboard_verification"
        case nonceRetrieval = "nonce_retrieval"
        case appPasswordGeneration = "app_password_generation"
        case userRoleCheck = "user_role_check"
        case wooPluginCheck = "woo_plugin_check"
        case appPasswordAuthorizationURL = "app_password_authorization_url"
    }

    let step: Step
    let statusCode: Int?
    let kind: Kind
    let diagnostics: UnexpectedStoreResponseError.Diagnostics?

    // Generic error logging must not expose support-only excerpts.
    var description: String { "Unexpected login response (\(step.rawValue), \(kind.rawValue))." }
    var debugDescription: String { description }

    init?(error: Error, step: Step) {
        let underlying = (error as? RoleEligibilityError)?.underlyingError ?? error
        guard let response = underlying as? UnexpectedStoreResponseError else { return nil }
        self.step = step
        self.statusCode = response.statusCode
        self.kind = response.kind
        self.diagnostics = response.diagnostics
    }

    init(stage: CookieNonceAuthenticationResponseStage, statusCode: Int? = nil, kind: Kind? = nil,
         diagnostics: UnexpectedStoreResponseError.Diagnostics? = nil) {
        self.step = switch stage {
        case .preflight: .loginPage
        case .credentials: .credentialsSubmission
        case .dashboard: .dashboardVerification
        case .nonce: .nonceRetrieval
        }
        self.statusCode = statusCode
        self.kind = kind ?? (statusCode == nil ? .unexpectedContent : .unacceptableStatusCode)
        self.diagnostics = diagnostics
    }
}
