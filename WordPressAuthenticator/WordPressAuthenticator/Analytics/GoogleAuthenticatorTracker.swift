import Foundation

/// Provides all the business logic for tracking Google Authentication events.
///
class GoogleAuthenticatorTracker {
    
    /// The backing analytics tracker for the Google sign in flows.
    ///
    private let analyticsTracker: AnalyticsTracker

    /// The legacy analytics tracker for the Google sign in flows.
    ///
    private let legacyTracker = LegacyGoogleAuthenticatorTracker()
    
    private let enableUnifiedTracks: Bool
    
    init(enableUnifiedTracks: Bool, context: AnalyticsTracker.Context) {
        self.analyticsTracker = AnalyticsTracker(context: context)
        self.enableUnifiedTracks = enableUnifiedTracks
    }
    
    // MARK: -  Tracking Support
    
    func track(_ event: AnalyticsEvent) {
        analyticsTracker.track(event)
    }
    
    func trackSigninStart(authType: GoogleAuthType) {
        switch authType {
        case .login:
            legacyTracker.trackLoginButtonTapped()
        case .signup:
            legacyTracker.trackCreateAccountInitiated()
        }
        
        guard enableUnifiedTracks else {
            return
        }
        
        switch authType {
        case .login:
            trackLogin(step: .start)
        case .signup:
            trackSignup(step: .start)
        }
     }
    
    func trackSigninSuccess(authType: GoogleAuthType) {
        legacyTracker.trackSigninSuccess()
        
        guard enableUnifiedTracks else {
            return
        }
        
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
        switch authType {
        case .login:
            legacyTracker.trackLoginButtonFailure(error: error)
        case .signup:
            legacyTracker.trackSignupButtonFailure(error: error)
        }
        
        guard enableUnifiedTracks else {
            return
        }
        
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        trackFailure(failure: errorMessage)
    }
    

    func trackSignupFailure(error: Error) {
        legacyTracker.trackSignupFailure(error: error)
        
        guard enableUnifiedTracks else {
            return
        }
        
        let errorMessage = error.localizedDescription
        trackFailure(failure: errorMessage)
    }
    
    /// Tracks a change of flow from signup to login.
    ///
    func trackLoginInstead() {
        legacyTracker.trackLoginInstead()
        
        guard enableUnifiedTracks else {
            return
        }
        
        trackLogin(step: .start)
        trackLogin(step: .success)
    }
    
    /// Tracks the request of a 2FA code to the user.
    ///
    func trackTwoFactorAuthenticationRequested() {
        legacyTracker.trackTwoFactorAuhenticationRequested()
        
        guard enableUnifiedTracks else {
            return
        }
        
        trackLogin(step: .twoFactorAuthentication)
    }
    
    func trackWPPasswordNeeded() {
        legacyTracker.trackWPPasswordNeeded()
    }
    
    func trackSocialErrorUnknownUser() {
        legacyTracker.trackSocialErrorUnknownUser()
    }
    
    func trackAccountCreated() {
        legacyTracker.trackAccountCreated()
    }
}

// MARK: - Tracking Convenience Methods

extension GoogleAuthenticatorTracker {
    
    func trackLogin(step: AnalyticsTracker.Step) {
        analyticsTracker.track(step: step, flow: .googleLogin)
    }
    
    func trackSignup(step: AnalyticsTracker.Step) {
        analyticsTracker.track(step: step, flow: .googleSignup)
    }
    
    func trackFailure(failure: String) {
        analyticsTracker.track(failure: failure)
    }
}
