import XCTest
import WordPressAuthenticator

class WordPressSourceTagTests: XCTestCase {
    
    func testGeneralLoginSourceTag() {
        let tag = WordPressSupportSourceTag.generalLogin
        
        let nameExpectation = "generalLogin"
        let originExpectation = "origin:login-screen"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testJetpackLoginSourceTag() {
        let tag = WordPressSupportSourceTag.jetpackLogin
        
        let nameExpectation = "jetpackLogin"
        let originExpectation = "origin:jetpack-login-screen"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testLoginEmailSourceTag() {
        let tag = WordPressSupportSourceTag.loginEmail
        
        let nameExpectation = "loginEmail"
        let originExpectation = "origin:login-email"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testLoginAppleSourceTag() {
        let tag = WordPressSupportSourceTag.loginApple
        
        let nameExpectation = "loginApple"
        let originExpectation = "origin:login-apple"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testlogin2FASourceTag() {
        let tag = WordPressSupportSourceTag.login2FA
        
        let nameExpectation = "login2FA"
        let originExpectation = "origin:login-2fa"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testLoginMagicLinkSourceTag() {
        let tag = WordPressSupportSourceTag.loginMagicLink
        
        let nameExpectation = "loginMagicLink"
        let originExpectation = "origin:login-magic-link"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testSiteAddressSourceTag() {
        let tag = WordPressSupportSourceTag.loginSiteAddress
        
        let nameExpectation = "loginSiteAddress"
        let originExpectation = "origin:login-site-address"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testLoginUsernameSourceTag() {
        let tag = WordPressSupportSourceTag.loginUsernamePassword
        
        let nameExpectation = "loginUsernamePassword"
        let originExpectation = "origin:login-username-password"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testLoginUsernamePasswordSourceTag() {
        let tag = WordPressSupportSourceTag.loginWPComUsernamePassword
        
        let nameExpectation = "loginWPComUsernamePassword"
        let originExpectation = "origin:wpcom-login-username-password"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testLoginWPComPasswordSourceTag() {
        let tag = WordPressSupportSourceTag.loginWPComPassword
        
        let nameExpectation = "loginWPComPassword"
        let originExpectation = "origin:login-wpcom-password"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testWPComSignupEmailSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignupEmail
        
        let nameExpectation = "wpComSignupEmail"
        let originExpectation = "origin:wpcom-signup-email-entry"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testWPComSignupSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignup
        
        let nameExpectation = "wpComSignup"
        let originExpectation = "origin:signup-screen"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testWPComSignupWaitingForGoogleSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignupWaitingForGoogle
        
        let nameExpectation = "wpComSignupWaitingForGoogle"
        let originExpectation = "origin:signup-waiting-for-google"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testWPComAuthGoogleSignupWaitingForGoogleSourceTag() {
        let tag = WordPressSupportSourceTag.wpComAuthWaitingForGoogle
        
        let nameExpectation = "wpComAuthWaitingForGoogle"
        let originExpectation = "origin:auth-waiting-for-google"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testWPComAuthGoogleSignupConfirmationSourceTag() {
        let tag = WordPressSupportSourceTag.wpComAuthGoogleSignupConfirmation
        
        let nameExpectation = "wpComAuthGoogleSignupConfirmation"
        let originExpectation = "origin:auth-google-signup-confirmation"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testWPComSignupMagicLinkSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignupMagicLink
        
        let nameExpectation = "wpComSignupMagicLink"
        let originExpectation = "origin:signup-magic-link"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
    
    func testWPComSignupAppleSourceTag() {
        let tag = WordPressSupportSourceTag.wpComSignupApple
        
        let nameExpectation = "wpComSignupApple"
        let originExpectation = "origin:signup-apple"
        
        XCTAssertEqual(tag.name, nameExpectation)
        XCTAssertEqual(tag.origin, originExpectation)
    }
}
