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

    func test_show_when_anchored_in_regular_width_and_compact_height_then_keeps_native_dismissal_available() throws {
        // Given
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 956, height: 440))
        window.traitOverrides.horizontalSizeClass = .regular
        window.traitOverrides.verticalSizeClass = .compact
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        self.window = window
        let anchor = UIButton(frame: CGRect(x: 16, y: 16, width: 80, height: 44))
        presenter.view.addSubview(anchor)
        let viewController = BottomSheetPresentableViewController()
        let bottomSheet = BottomSheetViewController(childViewController: viewController)

        // When
        bottomSheet.show(from: presenter, sourceView: anchor)

        // Then
        let popover = try XCTUnwrap(bottomSheet.popoverPresentationController)
        XCTAssertEqual(bottomSheet.modalPresentationStyle, .popover)
        XCTAssertTrue(popover.sourceView === anchor)
        XCTAssertTrue(popover.adaptiveSheetPresentationController.prefersEdgeAttachedInCompactHeight,
                      "An anchored picker must keep native sheet dismissal available at compact height")
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
