import Aztec
import WordPressEditor
import XCTest

@testable import WooCommerce

final class AztecBoldFormatBarCommandTests: XCTestCase {

    func testFormattingIdentifier() {
        let command = AztecBoldFormatBarCommand()
        XCTAssertEqual(command.formattingIdentifier, .bold)
    }

    func testTogglingCommand() {
        let command = AztecBoldFormatBarCommand()

        let text = "test"
        let unboldedHTML = "<p>test</p>"
        let boldedHTML = "<p><strong>test</strong></p>"

        let editorView = EditorView(defaultFont: .body,
                                    defaultHTMLFont: .body,
                                    defaultParagraphStyle: .default,
                                    defaultMissingImage: .asideImage)
        editorView.richTextView.text = text
        editorView.richTextView.selectedRange = NSRange(location: 0, length: editorView.richTextView.text.count)
        XCTAssertEqual(editorView.getHTML(), unboldedHTML)

        let formatBarItem = FormatBarItem(image: .bellImage)
        let formatBar = FormatBar()
        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertEqual(editorView.getHTML(), boldedHTML)

        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertEqual(editorView.getHTML(), unboldedHTML)
    }

}
