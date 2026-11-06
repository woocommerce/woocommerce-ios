import XCTest

@testable import WordPressUI

class BottomSheetViewControllerTests: XCTestCase {

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
    @MainActor
    func testAddGivenVCViewToTheBottomSheetSubviews() {
        // Given
        let viewController = BottomSheetPresentableViewController()
        let bottomSheet = BottomSheetViewController(childViewController: viewController)
        bottomSheet.modalPresentationStyle = .formSheet

        // When
        bottomSheet.loadViewIfNeeded()

        // Then
        XCTAssertTrue(bottomSheet.view.subviews.flatMap { $0.subviews }.contains(viewController.view))
        let grip = bottomSheet.view.subviews.compactMap { $0 as? UIStackView }.first?.arrangedSubviews.first
        XCTAssertEqual(grip?.isHidden, true, "Native form sheets must not show the custom drawer grip")
    }
}

private class BottomSheetPresentableViewController: UIViewController, DrawerPresentable {
    var initialHeight: CGFloat = 0
}
