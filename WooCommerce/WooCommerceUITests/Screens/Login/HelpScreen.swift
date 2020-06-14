import Foundation
import XCTest

private struct ElementStringIDs {
    static let dismissButton = "Dismiss"
    static let contactSupport = "Contact Support"
    
}

final class HelpScreen: BaseScreen {
    private let contactSupport: XCUIElement
    private let dismissButton: XCUIElement


init() {
    let app = XCUIApplication()
    contactSupport = app.cells[ElementStringIDs.contactSupport]
    dismissButton = app.buttons[ElementStringIDs.dismissButton]
    
    super.init(element: contactSupport)
    
    }
    static func helpScreenLoads() -> Bool {
        let expectedElement = XCUIApplication().cells [ElementStringIDs.contactSupport]
        return expectedElement.exists && expectedElement.isHittable
    
    }
    func closeHelpMenu() -> LoginEmailScreen {
        dismissButton.tap()
        return LoginEmailScreen()

    }
    
    }
