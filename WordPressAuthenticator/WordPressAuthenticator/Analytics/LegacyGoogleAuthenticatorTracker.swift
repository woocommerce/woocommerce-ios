import Foundation

class LegacyGoogleAuthenticatorTracker {
    
    /// The method used for analytics tracking.  Useful for overriding in automated tests.
    ///
    typealias BackingTrackerMethod = (_ event: WPAnalyticsStat, _ properties: [String: String]) -> ()
    
    /// The method used for analytics tracking.  Useful for overriding in automated tests.
    ///
    private let backingTrackerMethod: BackingTrackerMethod
    
    // MARK: - Initializers
    
    init(track: @escaping BackingTrackerMethod = WPAnalytics.track) {
        self.backingTrackerMethod = track
    }
    
    // MARK: - Tracking Support
    
    /// Tracks events.  Overrides the `source` param so that it's set to `"google"`.
    ///
    func track(_ event: WPAnalyticsStat, properties: [String: String] = [:]) {
        var trackProperties = properties
        trackProperties["source"] = "google"
        backingTrackerMethod(event, trackProperties)
    }
    
    // MARK: - Tracking Specific Events
    
    func trackLoginButtonTapped() {
        track(.loginSocialButtonClick)
    }
    
    func trackCreateAccountInitiated() {
        track(.createAccountInitiated)
    }
    
    func trackSigninSuccess() {
        track(.signedIn)
        track(.loginSocialSuccess)
    }
    
    func trackLoginButtonFailure(error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        let properties = ["error": errorMessage]
        
        track(.loginSocialButtonFailure, properties: properties)
    }
    
    func trackSignupButtonFailure(error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        let properties = ["error": errorMessage]
        
        track(.signupSocialButtonFailure, properties: properties)
    }
    
    func trackSignupFailure(error: Error) {
        let errorMessage = error.localizedDescription
        
        track(.signupSocialFailure, properties: ["error": errorMessage])
    }
    
    func trackLoginInstead() {
        track(.signedIn)
        track(.signupSocialToLogin)
        track(.loginSocialSuccess)
    }
    
    /// Tracks the request of a 2FA code to the user.
    ///
    func trackTwoFactorAuhenticationRequested() {
        track(.loginSocial2faNeeded)
    }
    
    func trackWPPasswordNeeded() {
        track(.loginSocialAccountsNeedConnecting)
    }
    
    func trackSocialErrorUnknownUser() {
        track(.loginSocialErrorUnknownUser)
    }
    
    func trackAccountCreated() {
        // This stat is part of a funnel that provides critical information.  Before
        // making ANY modification to this stat please refer to: p4qSXL-35X-p2
        track(.createdAccount)
        track(.signedIn)
        track(.signupSocialSuccess)
    }
}
