import ScreenObject
import XCTest

public final class CustomerNoteScreen: ScreenObject {

    private let noteTextEditorGetter: (XCUIApplication) -> XCUIElement = {
        $0.textViews["edit-note-text-editor"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["edit-note-done-button"]
    }

    private var noteTextEditor: XCUIElement { noteTextEditorGetter(app) }

    private var doneButton: XCUIElement { doneButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ noteTextEditorGetter ],
            app: app
        )
    }

    /// Enters a customer note.
    /// - Parameter text: Text to enter as the customer note.
    /// - Returns: Customer Note screen object.
    @discardableResult
    public func enterNote(_ text: String) throws -> Self {
        noteTextEditor.typeText(text)
        return self
    }

    /// Confirms entered note and closes Customer Note screen.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func confirmNote() throws -> UnifiedOrderScreen {
        doneButton.tap()
        return try UnifiedOrderScreen()
    }
}
