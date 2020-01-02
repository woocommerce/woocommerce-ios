import Aztec
import WordPressEditor
import XCTest

@testable import WooCommerce

final class AztecSourceCodeFormatBarCommandTests: XCTestCase {

    func testFormattingIdentifier() {
        let command = AztecSourceCodeFormatBarCommand()
        XCTAssertEqual(command.formattingIdentifier, .sourcecode)
    }

    func testTogglingCommand() {
        let command = AztecSourceCodeFormatBarCommand()

        let text = "test"
        let originalHTML = "<p>test</p>"

        let editorView = EditorView(defaultFont: .body,
                                    defaultHTMLFont: .body,
                                    defaultParagraphStyle: .default,
                                    defaultMissingImage: .asideImage)
        editorView.richTextView.text = text
        XCTAssertEqual(editorView.getHTML(), originalHTML)

        let formatBarItem = FormatBarItem(image: .bellImage)
        let formatBar = FormatBar()
        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertEqual(editorView.editingMode, .html)
        XCTAssertFalse(formatBar.enabled)

        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertEqual(editorView.editingMode, .richText)
        XCTAssertTrue(formatBar.enabled)
    }

}
