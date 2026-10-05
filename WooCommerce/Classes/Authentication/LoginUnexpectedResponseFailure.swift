import Yosemite
import enum NetworkingCore.CookieNonceAuthenticationResponseStage

/// Context for an unexpected response during login. Diagnostics never enter analytics properties.
struct LoginUnexpectedResponseFailure: Equatable {
    enum LoginFlow: String {
        case siteCredentials = "site_credentials"
        case appPassword = "app_password"
        case storePicker = "store_picker"
    }

    enum Kind: String {
        case unexpectedContent = "unexpected_content"
        case unacceptableStatusCode = "unacceptable_status_code"
    }

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

    init?(error: Error, step: Step) {
        let underlying = (error as? RoleEligibilityError)?.underlyingError ?? error
        guard let response = underlying as? UnexpectedStoreResponseError else { return nil }
        self.step = step
        self.statusCode = response.statusCode
        self.kind = response.kind == .unexpectedContent ? .unexpectedContent : .unacceptableStatusCode
        self.diagnostics = response.diagnostics
    }

    init(stage: CookieNonceAuthenticationResponseStage, statusCode: Int? = nil) {
        self.step = switch stage {
        case .preflight: .loginPage
        case .credentials: .credentialsSubmission
        case .dashboard: .dashboardVerification
        case .nonce: .nonceRetrieval
        }
        self.statusCode = statusCode
        self.kind = statusCode == nil ? .unexpectedContent : .unacceptableStatusCode
        self.diagnostics = nil
    }
}
