import Foundation

extension GoogleAuthenticatorTracker {
    class LegacyGoogleAuthenticatorTracker {
        
        // MARK: - Tracking Support
        
        /// Some of the methods we're tracking use `WPAnalyticsStat`.  This method offers legacy support so that we don't need to migrate
        /// all of those methods to `AnalyticsEvent`.
        ///
        func track(_ event: WPAnalyticsStat, properties: [AnyHashable: Any] = [:]) {
            var trackProperties = properties
            trackProperties["source"] = "google"
            WordPressAuthenticator.track(event, properties: trackProperties)
        }
        
        // MARK: - Tracking Specific Events
        
        func trackSignInStart(authType: GoogleAuthType) {
            switch authType {
            case .login:
                track(.loginSocialButtonClick)
            case .signup:
                track(.createAccountInitiated)
            }
        }
        
        func trackSignInSuccess() {
            track(.signedIn)
            track(.loginSocialSuccess)
        }
        
        func trackSignInFailure(authType: GoogleAuthType, errorMessage: String) {
            let properties = ["error": errorMessage]

            switch authType {
            case .login:
                track(.loginSocialButtonFailure, properties: properties)
            case .signup:
                track(.signupSocialButtonFailure, properties: properties)
            }
        }
        
        func trackSignUpFailure(errorMessage: String) {
            track(.signupSocialFailure, properties: ["error": errorMessage])
        }
        
        func trackLoginInstead() {
            track(.signupSocialToLogin)
            track(.signedIn)
            track(.loginSocialSuccess)
        }
        
        /// Tracks the request of a 2FA code to the user.
        ///
        func trackTwoFactorAuhenticationRequested() {
            track(.loginSocial2faNeeded)
        }
    }
}
