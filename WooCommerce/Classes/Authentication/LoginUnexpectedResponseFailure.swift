import enum NetworkingCore.CookieNonceAuthenticationResponseStage

/// Response-free context for an unexpected response during login. The originating flow belongs to the caller.
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
    }

    let step: Step
    let statusCode: Int?
    var kind: Kind { statusCode == nil ? .unexpectedContent : .unacceptableStatusCode }

    init(stage: CookieNonceAuthenticationResponseStage, statusCode: Int? = nil) {
        self.step = switch stage {
        case .preflight: .loginPage
        case .credentials: .credentialsSubmission
        case .dashboard: .dashboardVerification
        case .nonce: .nonceRetrieval
        }
        self.statusCode = statusCode
    }
}
