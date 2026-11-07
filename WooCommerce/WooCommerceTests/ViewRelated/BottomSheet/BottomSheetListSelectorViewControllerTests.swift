import Testing
import UIKit
import WordPressUI
@testable import WooCommerce

@MainActor
struct BottomSheetListSelectorViewControllerTests {
    @Test func test_viewDidLayoutSubviews_when_popover_relayouts_at_a_different_size_then_layout_does_not_recurse() {
        // Given
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: .nameAscending) { _ in }
        let selector = BottomSheetListSelectorViewController(viewProperties: BottomSheetListSelectorViewProperties(),
                                                             command: command,
                                                             onDismiss: nil)
        let popover = NonConvergingPopoverViewController(content: BottomSheetViewController(childViewController: selector))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 1366))
        window.rootViewController = popover
        window.makeKeyAndVisible()

        // When
        popover.view.layoutIfNeeded()

        // Then
        #expect(popover.maximumResizeDepth == 1)
        #expect(selector.preferredContentSize.height > 0)
        window.isHidden = true
    }
}

/// Mimics `UIPopoverPresentationController`, which re-lays out its content synchronously when the content's preferred size changes.
/// It lays the content out narrower than requested, so the size never settles.
private final class NonConvergingPopoverViewController: UIViewController {
    private static let maximumDepth = 20

    private let content: UIViewController
    private var resizeDepth = 0
    private(set) var maximumResizeDepth = 0

    init(content: UIViewController) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(content)
        content.view.frame = CGRect(x: 0, y: 0, width: 400, height: 600)
        view.addSubview(content.view)
        content.didMove(toParent: self)
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        resizeDepth += 1
        defer { resizeDepth -= 1 }
        maximumResizeDepth = max(maximumResizeDepth, resizeDepth)
        guard resizeDepth < Self.maximumDepth else {
            return
        }
        let width = max(container.preferredContentSize.width - 1, 1)
        content.view.frame.size = CGSize(width: width, height: content.view.frame.height)
        content.view.layoutIfNeeded()
    }
}
