import GoogleSignIn
import WordPressKit

// MARK: - WordPressAuthenticator Configuration
//
public struct WordPressAuthenticatorConfiguration {

    /// WordPress.com Client ID
    ///
    let wpcomClientId: String

    /// WordPress.com Secret
    ///
    let wpcomSecret: String

    /// Client App: Used for Magic Link purposes.
    ///
    let wpcomScheme: String

    /// WordPress.com Terms of Service URL
    ///
    let wpcomTermsOfServiceURL: String

    /// WordPress.com Base URL for OAuth
    ///
    let wpcomBaseURL: String

    /// WordPress.com API Base URL
    ///
    let wpcomAPIBaseURL: String

    /// The URL of a webpage which has details about What is WordPress.com?.
    ///
    /// Displayed in the WordPress.com login page. The button/link will not be displayed if this value is nil.
    ///
    let whatIsWPComURL: String?

    /// GoogleLogin Client ID
    ///
    let googleLoginClientId: String

    /// GoogleLogin ServerClient ID
    ///
    let googleLoginServerClientId: String

    /// GoogleLogin Callback Scheme
    ///
    let googleLoginScheme: String

    /// UserAgent
    ///
    let userAgent: String

    /// Flag indicating which Log In flow to display.
    /// If enabled, when Log In is selected, a button view is displayed with options.
    /// If disabled, when Log In is selected, the email login view is displayed with alternative options.
    ///
    let showLoginOptions: Bool

    /// Flag indicating if Sign Up UX is enabled for all services.
    ///
    let enableSignUp: Bool

    /// Hint buttons help users complete a step in the unified auth flow. Enabled by default.
    /// If enabled, "Find your site address", "Reset your password", and others will be displayed.
    /// If disabled, none of the hint buttons will appear on the unified auth flows.
    let displayHintButtons: Bool

    /// Flag indicating if the Sign In With Apple option should be displayed.
    ///
    let enableSignInWithApple: Bool

    /// Flag indicating if signing up via Google is enabled.
    /// This only applies to the unified Google flow.
    /// When a user attempts to log in with a nonexistent account:
    ///     If enabled, the user will be redirected to Google signup.
    ///     If disabled, a view is displayed providing the user with other options.
    ///
    let enableSignupWithGoogle: Bool

    /// Flag for the unified login/signup flows.
    /// If disabled, none of the unified flows will display.
    /// If enabled, all unified flows will display.
    ///
    let enableUnifiedAuth: Bool

    /// Flag for the new prologue carousel.
    /// If disabled, displays the old carousel.
    /// If enabled, displays the new carousel.
    let enableUnifiedCarousel: Bool

    /// Flag for the unified login/signup flows.
    /// If disabled, the "Continue With WordPress" button in the login prologue is shown first.
    /// If enabled, the "Enter your existing site address" button in the login prologue is shown first.
    /// Default value is disabled
    let continueWithSiteAddressFirst: Bool

    /// If enabled shows a "Sign in with site credentials" button in `GetStartedViewController` when landing in the screen after entering site address
    ///  Used to enable sign-in to self-hosted sites using WordPress.org credentials.
    ///  Disabled by default
    let enableSiteCredentialsLoginForSelfHostedSites: Bool

    /// If enabled, we will ask for WPCOM login after signing in using .org site credentials.
    ///  Disabled by default
    let isWPComLoginRequiredForSiteCredentialsLogin: Bool

    /// Designated Initializer
    ///
    public init (wpcomClientId: String,
                 wpcomSecret: String,
                 wpcomScheme: String,
                 wpcomTermsOfServiceURL: String,
                 wpcomBaseURL: String = WordPressComOAuthClient.WordPressComOAuthDefaultBaseUrl,
                 wpcomAPIBaseURL: String = WordPressComOAuthClient.WordPressComOAuthDefaultApiBaseUrl,
                 whatIsWPComURL: String? = nil,
                 googleLoginClientId: String,
                 googleLoginServerClientId: String,
                 googleLoginScheme: String,
                 userAgent: String,
                 showLoginOptions: Bool = false,
                 enableSignUp: Bool = true,
                 enableSignInWithApple: Bool = false,
                 enableSignupWithGoogle: Bool = false,
                 enableUnifiedAuth: Bool = false,
                 enableUnifiedCarousel: Bool = false,
                 displayHintButtons: Bool = true,
                 continueWithSiteAddressFirst: Bool = false,
                 enableSiteCredentialsLoginForSelfHostedSites: Bool = false,
                 isWPComLoginRequiredForSiteCredentialsLogin: Bool = false) {

        self.wpcomClientId = wpcomClientId
        self.wpcomSecret = wpcomSecret
        self.wpcomScheme = wpcomScheme
        self.wpcomTermsOfServiceURL = wpcomTermsOfServiceURL
        self.wpcomBaseURL = wpcomBaseURL
        self.wpcomAPIBaseURL = wpcomAPIBaseURL
        self.whatIsWPComURL = whatIsWPComURL
        self.googleLoginClientId =  googleLoginClientId
        self.googleLoginServerClientId = googleLoginServerClientId
        self.googleLoginScheme = googleLoginScheme
        self.userAgent = userAgent
        self.showLoginOptions = showLoginOptions
        self.enableSignUp = enableSignUp
        self.enableSignInWithApple = enableSignInWithApple
        self.enableUnifiedAuth = enableUnifiedAuth
        self.enableUnifiedCarousel = enableUnifiedCarousel
        self.displayHintButtons = displayHintButtons
        self.enableSignupWithGoogle = enableSignupWithGoogle
        self.continueWithSiteAddressFirst = continueWithSiteAddressFirst
        self.enableSiteCredentialsLoginForSelfHostedSites = enableSiteCredentialsLoginForSelfHostedSites
        self.isWPComLoginRequiredForSiteCredentialsLogin = isWPComLoginRequiredForSiteCredentialsLogin
    }
}
