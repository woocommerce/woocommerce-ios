import UITestsFoundation
import XCTest

class LoginFlow {

    /// Attempts to log in with WPCom if the CTA is available, otherwise try site address login.
    @discardableResult
    static func login() throws -> MyStoreScreen {
        if try PrologueScreen().isWPComLoginAvailable() {
            return try logInWithWPcom()
        }
        return try logInWithSiteAddress()
    }

    @discardableResult
    static func logInWithWPcom() throws -> MyStoreScreen {
        try PrologueScreen().tapContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .enterValidPassword()
            .enterValidTwoFACode()

        return try LoginEpilogueScreen()
            .verifyEpilogueDisplays(email: "e2eflowtestingmobile@example.com", siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()
    }

    @discardableResult
    static func logInWithSiteAddress() throws -> MyStoreScreen {
        return try PrologueScreen()
            .tapLogIn()
            .proceedWith(siteUrl: TestCredentials.siteUrl)
            .proceedWith(email: TestCredentials.emailAddress)
            .enterValidPassword()
            .enterValidTwoFACode()
    }
}
