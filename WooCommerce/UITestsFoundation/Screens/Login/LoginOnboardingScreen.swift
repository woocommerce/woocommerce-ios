import ScreenObject
import XCTest

public final class LoginOnboardingScreen: ScreenObject {

    private let skipOnboardingButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Login Onboarding Skip Button"]
    }

    private var skipOnboardingButton: XCUIElement { skipOnboardingButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: skipOnboardingButtonGetter,
            app: app
        )
    }

    public func skipOnboarding() throws -> PrologueScreen {
        skipOnboardingButton.tap()
        return try PrologueScreen()
    }
}
