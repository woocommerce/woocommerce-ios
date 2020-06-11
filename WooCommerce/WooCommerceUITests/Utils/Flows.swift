import XCTest

class Flows {
    @discardableResult
    static func loginIfNeeded(email: String, password: String) -> MyStoreScreen {
        if WelcomeScreen.isLoaded() {
            return WelcomeScreen()
                .selectLogin()
                .proceedWith(email: email)
                .proceedWithPassword()
                .proceedWith(password: password)
                .continueWithSelectedSite()
        }
        return MyStoreScreen()
    }
}
