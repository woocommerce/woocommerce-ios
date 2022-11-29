import UITestsFoundation
import XCTest

class LoginFlow {

    @discardableResult
    static func logInWithWPcom() throws -> MyStoreScreen {
        try PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)

        return try LoginEpilogueScreen()
            .verifyEpilogueDisplays(email: "e2eflowtestingmobile@example.com", siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()
    }
}
