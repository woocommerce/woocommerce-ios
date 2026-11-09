import XCTest

@testable import WordPressUI

@MainActor
class BottomSheetViewControllerTests: XCTestCase {
    private var window: UIWindow?

    override func tearDown() {
        window = nil
        super.tearDown()
    }

    /// - Add the given ViewController as a child View Controller
    ///
    func testAddTheGivenViewControllerAsAChildViewController() {
        let viewController = BottomSheetPresentableViewController()
        let bottomSheet = BottomSheetViewController(childViewController: viewController)

        bottomSheet.viewDidLoad()

        XCTAssertTrue(bottomSheet.children.contains(viewController))
    }

    /// - Add the given ViewController view to the subviews of the Bottom Sheet
    ///
    func testAddGivenVCViewToTheBottomSheetSubviews() {
        // Given
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 956, height: 440))
        window.traitOverrides.horizontalSizeClass = .regular
        window.traitOverrides.verticalSizeClass = .compact
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        self.window = window
        let viewController = BottomSheetPresentableViewController()
        let bottomSheet = BottomSheetViewController(childViewController: viewController)

        // When
        bottomSheet.show(from: presenter)

        // Then
        XCTAssertEqual(bottomSheet.modalPresentationStyle, .formSheet)
        XCTAssertEqual(bottomSheet.sheetPresentationController?.prefersEdgeAttachedInCompactHeight, true)
        XCTAssertTrue(bottomSheet.view.subviews.flatMap { $0.subviews }.contains(viewController.view))
        let grip = bottomSheet.view.subviews.compactMap { $0 as? UIStackView }.first?.arrangedSubviews.first
        XCTAssertEqual(grip?.isHidden, true, "Native form sheets must not show the custom drawer grip")
    }
}

private class BottomSheetPresentableViewController: UIViewController, DrawerPresentable {
    var initialHeight: CGFloat = 0
}
