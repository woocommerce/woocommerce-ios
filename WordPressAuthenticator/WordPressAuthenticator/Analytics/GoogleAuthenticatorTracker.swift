import Foundation

/// Provides all the business logic for tracking Google Authentication events.
///
class GoogleAuthenticatorTracker {
    
    /// The backing analytics tracker for the Google sign in flows.
    ///
    private let analyticsTracker: AnalyticsTracker
    
    init(analyticsTracker: AnalyticsTracker) {
        self.analyticsTracker = analyticsTracker
    }
    
    // MARK: -  Tracking Support
    
    func trackSigninStart(authType: GoogleAuthType) {
        switch authType {
        case .login:
            analyticsTracker.set(flow: .googleLogin)
            analyticsTracker.track(step: .start)
        case .signup:
            analyticsTracker.set(flow: .googleSignup)
            analyticsTracker.track(step: .start)
        }
     }
    
    func trackSuccess() {
        analyticsTracker.track(step: .success)
    }
    
    /// Tracks a failure in any step of the signin process.
    ///
    func trackSigninFailure(authType: GoogleAuthType, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        analyticsTracker.track(failure: errorMessage)
    }
    

    func trackSignupFailure(error: Error) {
        let errorMessage = error.localizedDescription
        analyticsTracker.track(failure: errorMessage)
    }
    
    /// Tracks a change of flow from signup to login.
    ///
    func trackLoginInstead() {
        analyticsTracker.set(flow: .googleLogin)
        analyticsTracker.track(step: .start)
        analyticsTracker.track(step: .success)
    }
    
    /// Tracks the request of a 2FA code to the user.
    ///
    func trackTwoFactorAuthenticationRequested() {
        analyticsTracker.track(step: .twoFactorAuthentication)
    }
    
    func trackPasswordRequested(authType: GoogleAuthType) {
        analyticsTracker.track(step: .userPasswordScreenShown)
    }
}

// MARK: - Tracking Convenience Methods

extension GoogleAuthenticatorTracker {

    private func trackFailure(failure: String) {
        
    }
}
