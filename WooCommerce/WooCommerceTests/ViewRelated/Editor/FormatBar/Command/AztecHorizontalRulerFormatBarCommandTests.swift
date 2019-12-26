import Aztec
import WordPressEditor
import XCTest

@testable import WooCommerce

final class AztecHorizontalRulerFormatBarCommandTests: XCTestCase {

    func testFormattingIdentifier() {
        let command = AztecHorizontalRulerFormatBarCommand()
        XCTAssertEqual(command.formattingIdentifier, .horizontalruler)
    }

    func testTogglingCommand() {
        let command = AztecHorizontalRulerFormatBarCommand()

        let text = "test"
        let originalHTML = "<p>test</p>"
        let formattedHTML = """
        <p>test
          <hr>
        </p>
        """

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
        XCTAssertEqual(editorView.getHTML(), formattedHTML)
    }

}
