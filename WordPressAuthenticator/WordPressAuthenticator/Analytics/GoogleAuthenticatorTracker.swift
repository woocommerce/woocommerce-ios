import Foundation

/// Provides all the business logic for tracking Google Authentication events.
///
class GoogleAuthenticatorTracker {
    
    /// The backing analytics tracker for the Google sign in flows.
    ///
    private let analyticsTracker: AnalyticsTracker
    
    init(context: AnalyticsTracker.Context) {
        self.analyticsTracker = AnalyticsTracker(context: context)
    }
    
    // MARK: -  Tracking Support
    
    func trackSigninStart(authType: GoogleAuthType) {
        switch authType {
        case .login:
            trackLogin(step: .start)
        case .signup:
            trackSignup(step: .start)
        }
     }
    
    func trackSigninSuccess(authType: GoogleAuthType) {
        switch authType {
        case .login:
            trackLogin(step: .success)
        case .signup:
            trackSignup(step: .success)
        }
    }
    
    /// Tracks a failure in any step of the signin process.
    ///
    func trackSigninFailure(authType: GoogleAuthType, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        trackFailure(failure: errorMessage)
    }
    

    func trackSignupFailure(error: Error) {
        let errorMessage = error.localizedDescription
        trackFailure(failure: errorMessage)
    }
    
    /// Tracks a change of flow from signup to login.
    ///
    func trackLoginInstead() {
        trackLogin(step: .start)
        trackLogin(step: .success)
    }
    
    /// Tracks the request of a 2FA code to the user.
    ///
    func trackTwoFactorAuthenticationRequested() {
        trackLogin(step: .twoFactorAuthentication)
    }
    
    func trackPasswordRequested(authType: GoogleAuthType) {
        switch authType {
        case .login:
            trackLogin(step: .userPasswordScreenShown)
        case .signup:
            trackSignup(step: .userPasswordScreenShown)
        }
    }
}

// MARK: - Tracking Convenience Methods

extension GoogleAuthenticatorTracker {

    private func trackLogin(step: AnalyticsTracker.Step) {
        analyticsTracker.track(step: step, flow: .googleLogin)
    }

    private func trackSignup(step: AnalyticsTracker.Step) {
        analyticsTracker.track(step: step, flow: .googleSignup)
    }

    private func trackFailure(failure: String) {
        analyticsTracker.track(failure: failure)
    }
}
