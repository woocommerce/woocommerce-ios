import ScreenObject
import XCTest

public final class LoginOnboardingScreen: ScreenObject {
    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: { $0.buttons["Login Onboarding Skip Button"] },
            app: app
        )
    }

    public func skipOnboarding() throws -> PrologueScreen {
        app.buttons["Login Onboarding Skip Button"].tap()
        return try PrologueScreen()
    }
}
