import ScreenObject
import XCTest

public final class PaymentsScreen: ScreenObject {
    private let collectPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["collect-payment"]
    }

    private let cardReaderManualsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["card-reader-manuals"]
    }

    private var collectPaymentButton: XCUIElement { collectPaymentButtonGetter(app) }
    private var cardReaderManualsButton: XCUIElement { cardReaderManualsButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ collectPaymentButtonGetter ],
            app: app
        )
    }

    @discardableResult
    public func tapCardReaderManuals() throws -> CardReaderManualsScreen {
        cardReaderManualsButton.tap()
        return try CardReaderManualsScreen()
    }
}
