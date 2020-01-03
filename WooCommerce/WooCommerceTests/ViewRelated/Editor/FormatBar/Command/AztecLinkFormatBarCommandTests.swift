import Aztec
import WordPressEditor
import XCTest

@testable import WooCommerce

final class AztecLinkFormatBarCommandTests: XCTestCase {

    private let viewController = UIViewController()

    func testFormattingIdentifier() {
        let command = AztecLinkFormatBarCommand(linkDialogPresenter: viewController)
        XCTAssertEqual(command.formattingIdentifier, .link)
    }

    func testTogglingCommand() {
        let command = AztecLinkFormatBarCommand(linkDialogPresenter: viewController)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        let editorView = EditorView(defaultFont: .body,
                                    defaultHTMLFont: .body,
                                    defaultParagraphStyle: .default,
                                    defaultMissingImage: .asideImage)
        editorView.richTextView.text = "test"
        editorView.richTextView.selectedRange = NSRange(location: 0, length: editorView.richTextView.text.count)
        let formatBarItem = FormatBarItem(image: .bellImage)
        let formatBar = FormatBar()
        command.handleAction(editorView: editorView,
                             formatBarItem: formatBarItem,
                             formatBar: formatBar)
        let presentedViewController = (viewController.presentedViewController as? UINavigationController)?.viewControllers.first
        XCTAssertTrue(presentedViewController is LinkSettingsViewController)
    }

}
