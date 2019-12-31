import Aztec
import WordPressEditor
import XCTest

@testable import WooCommerce

final class AztecBlockquoteFormatBarCommandTests: XCTestCase {

    func testFormattingIdentifier() {
        let command = AztecBlockquoteFormatBarCommand()
        XCTAssertEqual(command.formattingIdentifier, .blockquote)
    }

    func testTogglingCommand() {
        let command = AztecBlockquoteFormatBarCommand()

        let text = "test"
        let originalHTML = "<p>test</p>"
        let formattedHTML = "<blockquote>test</blockquote>"

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
        XCTAssertEqual(editorView.getHTML(), formattedHTML)

        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertEqual(editorView.getHTML(), originalHTML)
    }

}
