import UITestsFoundation
import XCTest

class LoginFlow {

    // Login with WordPress.com account flow
    @discardableResult
    static func login() throws -> MyStoreScreen {
       return try PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()
    }
}
