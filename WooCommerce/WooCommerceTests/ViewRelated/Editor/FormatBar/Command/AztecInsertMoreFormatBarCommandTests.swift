import Aztec
import WordPressEditor
import XCTest

@testable import WooCommerce

final class AztecInsertMoreFormatBarCommandTests: XCTestCase {

    func testFormattingIdentifier() {
        let command = AztecInsertMoreFormatBarCommand()
        XCTAssertEqual(command.formattingIdentifier, .more)
    }

    func testTogglingCommand() {
        let command = AztecInsertMoreFormatBarCommand()

        let text = "test"
        let originalHTML = "<p>test</p>"
        let formattedHTML = "<p>test<!--more--></p>"

        let editorView = EditorView(defaultFont: .body,
                                    defaultHTMLFont: .body,
                                    defaultParagraphStyle: .default,
                                    defaultMissingImage: .asideImage)
        editorView.richTextView.text = text

        // "Insert more" formatting requires at least one `TextViewAttachmentImageProvider`.
        let providers: [TextViewAttachmentImageProvider] = [
            SpecialTagAttachmentRenderer(),
        ]

        for provider in providers {
            editorView.richTextView.registerAttachmentImageProvider(provider)
        }


        XCTAssertEqual(editorView.getHTML(), originalHTML)

        let formatBarItem = FormatBarItem(image: .bellImage)
        let formatBar = FormatBar()
        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertEqual(editorView.getHTML(), formattedHTML)
    }

}
