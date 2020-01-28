import Aztec
import WordPressEditor
import XCTest

@testable import WooCommerce

final class AztecItalicFormatBarCommandTests: XCTestCase {

    func testFormattingIdentifier() {
        let command = AztecItalicFormatBarCommand()
        XCTAssertEqual(command.formattingIdentifier, .italic)
    }

    func testTogglingCommand() {
        let command = AztecItalicFormatBarCommand()

        let text = "test"
        let originalHTML = "<p>test</p>"
        let italicizedHTML = "<p><em>test</em></p>"

        let editorView = EditorView(defaultFont: .body,
                                    defaultHTMLFont: .body,
                                    defaultParagraphStyle: .default,
                                    defaultMissingImage: .asideImage)
        editorView.richTextView.text = text
        editorView.richTextView.selectedRange = NSRange(location: 0, length: editorView.richTextView.text.count)
        XCTAssertEqual(editorView.getHTML(), originalHTML)

        let formatBarItem = FormatBarItem(image: .bellImage)
        let formatBar = FormatBar()
        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertEqual(editorView.getHTML(), italicizedHTML)

        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertEqual(editorView.getHTML(), originalHTML)
    }

}
