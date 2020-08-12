//
//  LoginFacade.swift
//  WordPressAuthenticator
//
//  Created by Diego Rey Mendez on 12/08/2020.
//  Copyright © 2020 Automattic. All rights reserved.
//

import Foundation

extension LoginFacade {
    func requestOneTimeCode(with loginFields: LoginFields) {
        wordpressComOAuthClientFacade.requestOneTimeCode(withUsername: loginFields.username, password: loginFields.password, success: {
            if AuthenticatorAnalyticsTracker.shared.shouldUseLegacyTracker() {
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
            success: { newNonce in
                if let newNonce = newNonce {
                    loginFields.nonceInfo?.nonceSMS = newNonce
                }
            
                if AuthenticatorAnalyticsTracker.shared.shouldUseLegacyTracker() {
                    WordPressAuthenticator.track(.twoFactorSentSMS)
                }
        }) { (error, newNonce) in
            if let newNonce = newNonce {
                loginFields.nonceInfo?.nonceSMS = newNonce
            }
            DDLogError("Failed to request one time code");
        }
    }
}
