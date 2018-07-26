import WordPressShared


/// This enum contains all of the events we track in the app.
///
public enum WooAnalyticsStat: String {
    case applicationOpened                      = "application_opened"
    case applicationClosed                      = "application_closed"

    case signedIn                               = "signed_in"
    case logout                                 = "account_logout"
    case openedLogin                            = "login_accessed"
    case loginFailed                            = "login_failed_to_login"
    case loginAutoFillCredentialsFilled         = "login_autofill_credentials_filled"
    case loginAutoFillCredentialsUpdated        = "login_autofill_credentials_updated"
    case loginProloguePaged                     = "login_prologue_paged"
    case loginPrologueViewed                    = "login_prologue_viewed"
    case loginEmailFormViewed                   = "login_email_form_viewed"
    case loginMagicLinkOpenEmailClientViewed    = "login_magic_link_open_email_client_viewed"
    case loginMagicLinkRequestFormViewed        = "login_magic_link_request_form_viewed"
    case loginPasswordFormViewed                = "login_password_form_viewed"
    case loginURLFormViewed                     = "login_url_form_viewed"
    case loginURLHelpScreenViewed               = "login_url_help_screen_viewed"
    case loginUsernamePasswordFormViewed        = "login_username_password_form_viewed"
    case loginTwoFactorFormViewed               = "login_two_factor_form_viewed"
    case loginEpilogueViewed                    = "login_epilogue_viewed"
    case loginForgotPasswordClicked             = "login_forgot_password_clicked"
    case loginSocialButtonClick                 = "login_social_button_click"
    case loginSocialButtonFailure               = "login_social_button_failure"
    case loginSocialConnectSuccess              = "login_social_connect_success"
    case loginSocialConnectFailure              = "login_social_connect_failure"
    case loginSocialSuccess                     = "login_social_login_success"
    case loginSocialFailure                     = "login_social_login_failure"
    case loginSocial2faNeeded                   = "login_social_2fa_needed"
    case loginSocialAccountsNeedConnecting      = "login_social_accounts_need_connecting"
    case loginSocialErrorUnknownUser            = "login_social_error_unknown_user"
    case onePasswordFailed                      = "one_password_failed"
    case onePasswordLogin                       = "one_password_login"
    case onePasswordSignup                      = "one_password_signup"
}

public extension WooAnalyticsStat {

    /// Converts the provided WPAnalyticsStat into a WooAnalyticsStat.
    /// This whole process kinda stinks, but we need this for the `WordPressAuthenticatorDelegate`
    /// implementation. ☹️ Feel free to refactor later on!
    ///
    /// - Parameter stat: The WPAnalyticsStat to convert
    /// - Returns: The corresponding WooAnalyticsStat or nil if it cannot be converted
    ///
    static func valueOf(stat: WPAnalyticsStat) -> WooAnalyticsStat? {
        var wooEvent: WooAnalyticsStat? = nil

        switch stat {
        case .signedIn:
            wooEvent = WooAnalyticsStat.signedIn
        case .signedInToJetpack:
            wooEvent = WooAnalyticsStat.signedIn
        case .logout:
            wooEvent = WooAnalyticsStat.logout
        case .openedLogin:
            wooEvent = WooAnalyticsStat.openedLogin
        case .loginFailed:
            wooEvent = WooAnalyticsStat.loginFailed
        case .loginAutoFillCredentialsFilled:
            wooEvent = WooAnalyticsStat.loginAutoFillCredentialsFilled
        case .loginAutoFillCredentialsUpdated:
            wooEvent = WooAnalyticsStat.loginAutoFillCredentialsUpdated
        case .loginProloguePaged:
            wooEvent = WooAnalyticsStat.loginProloguePaged
        case .loginPrologueViewed:
            wooEvent = WooAnalyticsStat.loginPrologueViewed
        case .loginEmailFormViewed:
            wooEvent = WooAnalyticsStat.loginEmailFormViewed
        case .loginMagicLinkOpenEmailClientViewed:
            wooEvent = WooAnalyticsStat.loginMagicLinkOpenEmailClientViewed
        case .loginMagicLinkRequestFormViewed:
            wooEvent = WooAnalyticsStat.loginMagicLinkRequestFormViewed
        case .loginPasswordFormViewed:
             wooEvent = WooAnalyticsStat.loginPasswordFormViewed
        case .loginURLFormViewed:
            wooEvent = WooAnalyticsStat.loginURLFormViewed
        case .loginURLHelpScreenViewed:
            wooEvent = WooAnalyticsStat.loginURLHelpScreenViewed
        case .loginUsernamePasswordFormViewed:
            wooEvent = WooAnalyticsStat.loginUsernamePasswordFormViewed
        case .loginTwoFactorFormViewed:
            wooEvent = WooAnalyticsStat.loginTwoFactorFormViewed
        case .loginEpilogueViewed:
            wooEvent = WooAnalyticsStat.loginEpilogueViewed
        case .loginForgotPasswordClicked:
            wooEvent = WooAnalyticsStat.loginForgotPasswordClicked
        case .loginSocialButtonClick:
            wooEvent = WooAnalyticsStat.loginSocialButtonClick
        case .loginSocialButtonFailure:
            wooEvent = WooAnalyticsStat.loginSocialButtonFailure
        case .loginSocialConnectSuccess:
            wooEvent = WooAnalyticsStat.loginSocialConnectSuccess
        case .loginSocialConnectFailure:
            wooEvent = WooAnalyticsStat.loginSocialConnectFailure
        case .loginSocialSuccess:
            wooEvent = WooAnalyticsStat.loginSocialSuccess
        case .loginSocialFailure:
            wooEvent = WooAnalyticsStat.loginSocialFailure
        case .loginSocial2faNeeded:
            wooEvent = WooAnalyticsStat.loginSocial2faNeeded
        case .loginSocialAccountsNeedConnecting:
            wooEvent = WooAnalyticsStat.loginSocialAccountsNeedConnecting
        case .loginSocialErrorUnknownUser:
            wooEvent = WooAnalyticsStat.loginSocialErrorUnknownUser
        case .onePasswordFailed:
            wooEvent = WooAnalyticsStat.onePasswordFailed
        case .onePasswordLogin:
            wooEvent = WooAnalyticsStat.onePasswordLogin
        case .onePasswordSignup:
            wooEvent = WooAnalyticsStat.onePasswordSignup
        default:
            wooEvent = nil
        }

        return wooEvent
    }
}
