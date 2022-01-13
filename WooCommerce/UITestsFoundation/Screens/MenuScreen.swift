import ScreenObject
import XCTest

public final class MenuScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let tabBar = try! TabNavComponent()

    static var isVisible: Bool {
        (try? MenuScreen().isLoaded) ?? false
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            // TODO: Need updated ElementGetters for Menu screen
            expectedElementGetters: [ { $0.buttons["reviews-open-menu-button"] } ],
            app: app
        )
    }

    @discardableResult
    public func verifyMenuScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }
}
