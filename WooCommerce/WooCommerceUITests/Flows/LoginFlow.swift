import UITestsFoundation
import XCTest

class LoginFlow {

    @discardableResult
    static func logInWithWPcom() throws -> MyStoreScreen {
       return try PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()
    }
}
