import UITestsFoundation
import XCTest

class LoginFlow {

    @discardableResult
    static func logInWithWPcom() throws -> MyStoreScreen {
       return try LoginOnboardingScreen().skipOnboarding()
            .selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()
    }
}
