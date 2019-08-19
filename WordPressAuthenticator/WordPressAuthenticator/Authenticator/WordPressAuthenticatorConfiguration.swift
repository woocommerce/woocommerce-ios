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
    /// In the new flow, when Log In is selected, a button view is displayed with options.
    /// In the old flow, when Log In is selected, the email login view is displayed with alternative options.
    ///
    let showNewLoginFlow: Bool

    /// Flag indicating if the login options button view should be displayed in the site address flow.
    /// If enabled, the options button view will be displayed after the site address has been entered
    /// and verified.
    ///
    let showLoginOptionsFromSiteAddress: Bool
    
    /// Flag indicating if the Sign In With Apple option should be displayed.
    ///
    let enableSignInWithApple: Bool

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
                 showNewLoginFlow: Bool = false,
                 showLoginOptionsFromSiteAddress: Bool = false,
                 enableSignInWithApple: Bool = false) {

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
        self.showNewLoginFlow = showNewLoginFlow
        self.showLoginOptionsFromSiteAddress = showLoginOptionsFromSiteAddress
        self.enableSignInWithApple = enableSignInWithApple
    }
}
