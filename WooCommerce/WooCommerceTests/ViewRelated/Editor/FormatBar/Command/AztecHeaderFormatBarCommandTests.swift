import Aztec
import WordPressEditor
import XCTest

@testable import WooCommerce

final class AztecHeaderFormatBarCommandTests: XCTestCase {
    private let viewController = UIViewController()
    private let textView = TextView(defaultFont: .body, defaultMissingImage: .asideImage)
    private lazy var optionsTablePresenter = OptionsTablePresenter(presentingViewController: viewController, presentingTextView: textView)

    func testFormattingIdentifier() {
        let command = AztecHeaderFormatBarCommand(optionsTablePresenter: optionsTablePresenter)
        XCTAssertEqual(command.formattingIdentifier, .p)
    }

    func testTogglingCommand() {
        let command = AztecHeaderFormatBarCommand(optionsTablePresenter: optionsTablePresenter)

        let editorView = EditorView(defaultFont: .body,
                                    defaultHTMLFont: .body,
                                    defaultParagraphStyle: .default,
                                    defaultMissingImage: .asideImage)
        let formatBarItem = FormatBarItem(image: .bellImage)
        let formatBar = FormatBar()
        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertTrue(optionsTablePresenter.isOnScreen())

        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        XCTAssertFalse(optionsTablePresenter.isOnScreen())
    }
}
