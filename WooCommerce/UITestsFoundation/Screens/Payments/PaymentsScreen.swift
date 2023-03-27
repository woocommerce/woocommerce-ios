import ScreenObject
import XCTest

public final class PaymentsScreen: ScreenObject {
    private let collectPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["collect-payment"]
    }

    private let selectCardReaderManualsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["card-reader-manuals"]
    }

    private var collectPaymentButton: XCUIElement { collectPaymentButtonGetter(app) }
    private var selectCardReaderManualsButton: XCUIElement { selectCardReaderManualsButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ collectPaymentButtonGetter ],
            app: app
        )
    }

    @discardableResult
        selectCardReaderManualsButton.tap()
    public func tapCardReaderManuals() throws -> CardReaderManualsScreen {
        return try CardReaderManualsScreen()
    }
}
