import Foundation
import XCTest

final class OrderNoteScreen: BaseScreen {

    struct ElementStringIDs {
        static let addButton = "order-note-add-button"
        static let dismissButton = "order-note-dismiss-button"
        static let noteField = "order-note-text-field"
        static let emailNoteToggle = "order-note-email-switch"
    }
    enum Toggle {
        case on
        case off
    }

    private let addButton: XCUIElement
    private let dismissButton: XCUIElement
    private let noteField: XCUIElement
    private let emailNoteToggle: XCUIElement

    static var isVisible: Bool {
        let noteField = XCUIApplication().buttons[ElementStringIDs.noteField]
        return noteField.exists && noteField.isHittable
    }

    init() {
        addButton = XCUIApplication().navigationBars.buttons[ElementStringIDs.addButton]
        dismissButton = XCUIApplication().navigationBars.buttons[ElementStringIDs.dismissButton]
        noteField = XCUIApplication().textViews[ElementStringIDs.noteField]
        emailNoteToggle = XCUIApplication().cells[ElementStringIDs.emailNoteToggle]
        super.init(element: noteField)
    }

    func addNote(withText text: String, sendEmail state: Toggle) -> SingleOrderScreen {
        XCTAssert(!addButton.isEnabled, "Add button should not be enabled before writing note")
        writeNote(withText: text)
        XCTAssert(addButton.isEnabled, "Add button should be enabled after writing note")
        XCTAssert(!isEmailNoteEnabled(), "Email note option should be off by default")
        toggleEmailOption(to: state)
        addButton.tap()
        return SingleOrderScreen()
    }

    override func pop() {
        dismissButton.tap()
    }

    private func writeNote(withText text: String) {
        // Note field already has focus, so we can type into it immediately
        noteField.typeText(text)
    }

    private func toggleEmailOption(to state: Toggle) {
        switch state {
        case .on:
            if !isEmailNoteEnabled() {
                emailNoteToggle.tap()
                XCTAssert(isEmailNoteEnabled())
            }
        case .off:
            if isEmailNoteEnabled() {
                emailNoteToggle.tap()
                XCTAssert(!isEmailNoteEnabled())
            }
        }
    }

    private func isEmailNoteEnabled() -> Bool {
        return emailNoteToggle.value as! String == "1"
    }
}
