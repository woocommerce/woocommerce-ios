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
    /// If enabled, allows selected unified flows to display.
    ///
    let enableUnifiedAuth: Bool

    /// Hint buttons help users complete a step in the unified auth flow. Enabled by default.
    /// If enabled, "Find your site address", "Reset your password", and others will be displayed.
    /// If disabled, none of the hint buttons will appear on the unified auth flows.
    let displayHintButtons: Bool

    /// Flag indicating if the unified login by Site Address flow should display.
    ///
    let enableUnifiedSiteAddress: Bool

    /// Flag indicating if the unified Google flow should display.
    ///
    let enableUnifiedGoogle: Bool

    /// Flag indicating if the unified Apple flow should display.
    ///
    let enableUnifiedApple: Bool

    /// Flag indicating if the unified WordPress flow should display.
    ///
    let enableUnifiedWordPress: Bool

    /// Designated Initializer
    ///
    public init (wpcomClientId: String,
                 wpcomSecret: String,
                 wpcomScheme: String,
                 wpcomTermsOfServiceURL: String,
                 wpcomBaseURL: String = WordPressComOAuthClient.WordPressComOAuthDefaultBaseUrl,
                 wpcomAPIBaseURL: String = WordPressComOAuthClient.WordPressComOAuthDefaultApiBaseUrl,
                 googleLoginClientId: String,
                 googleLoginServerClientId: String,
                 googleLoginScheme: String,
                 userAgent: String,
                 showLoginOptions: Bool = false,
                 enableSignUp: Bool = true,
                 enableSignInWithApple: Bool = false,
                 enableSignupWithGoogle: Bool = false,
                 enableUnifiedAuth: Bool = false,
                 displayHintButtons: Bool = true,
                 enableUnifiedSiteAddress: Bool = false,
                 enableUnifiedGoogle: Bool = false,
                 enableUnifiedApple: Bool = false,
                 enableUnifiedWordPress: Bool = false) {

        self.wpcomClientId = wpcomClientId
        self.wpcomSecret = wpcomSecret
        self.wpcomScheme = wpcomScheme
        self.wpcomTermsOfServiceURL = wpcomTermsOfServiceURL
        self.wpcomBaseURL = wpcomBaseURL
        self.wpcomAPIBaseURL = wpcomAPIBaseURL
        self.googleLoginClientId =  googleLoginClientId
        self.googleLoginServerClientId = googleLoginServerClientId
        self.googleLoginScheme = googleLoginScheme
        self.userAgent = userAgent
        self.showLoginOptions = showLoginOptions
        self.enableSignUp = enableSignUp
        self.enableSignInWithApple = enableSignInWithApple
        self.enableUnifiedAuth = enableUnifiedAuth
        self.displayHintButtons = displayHintButtons
        self.enableUnifiedSiteAddress = enableUnifiedAuth && enableUnifiedSiteAddress
        self.enableUnifiedGoogle = enableUnifiedAuth && enableUnifiedGoogle
        self.enableSignupWithGoogle = enableSignupWithGoogle
        self.enableUnifiedApple = enableUnifiedAuth && enableUnifiedApple
        self.enableUnifiedWordPress = enableUnifiedAuth && enableUnifiedWordPress
    }
}
