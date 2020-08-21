import Foundation

extension LoginFacade {
    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }
    
    func requestOneTimeCode(with loginFields: LoginFields) {
        wordpressComOAuthClientFacade.requestOneTimeCode(
            withUsername: loginFields.username, 
            password: loginFields.password,
            success: { [weak self] in
                guard let self = self else {
                    return
                }
                
                if self.tracker.shouldUseLegacyTracker() {
                    WordPressAuthenticator.track(.twoFactorSentSMS)
                }
        }) { _ in
            DDLogError("Failed to request one time code")
        }
    }

    func requestSocial2FACode(with loginFields: LoginFields) {
        guard let nonce = loginFields.nonceInfo?.nonceSMS else {
            return
        }
        
        wordpressComOAuthClientFacade.requestSocial2FACode(
            withUserID: loginFields.nonceUserID,
            nonce: nonce,
            success: { [weak self] newNonce in
                guard let self = self else {
                    return
                }
                
                if let newNonce = newNonce {
                    loginFields.nonceInfo?.nonceSMS = newNonce
                }
            
                if self.tracker.shouldUseLegacyTracker() {
                    WordPressAuthenticator.track(.twoFactorSentSMS)
                }
        }) { (error, newNonce) in
            if let newNonce = newNonce {
                loginFields.nonceInfo?.nonceSMS = newNonce
            }
            DDLogError("Failed to request one time code");
        }
    }
    
    @objc
    public func trackSuccess() {
        tracker.track(step: .success)
    }
}
