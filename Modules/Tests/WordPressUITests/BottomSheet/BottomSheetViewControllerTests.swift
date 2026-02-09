import Testing
import UIKit
@testable import WordPressUI

@MainActor
struct `Bottom Sheet View Controller Tests` {

    /// - Add the given ViewController as a child View Controller
    ///
    @Test func `add the given view controller as a child view controller`() {
        let viewController = BottomSheetPresentableViewController()
        let bottomSheet = BottomSheetViewController(childViewController: viewController)

        bottomSheet.viewDidLoad()

        #expect(bottomSheet.children.contains(viewController))
    }

    /// - Add the given ViewController view to the subviews of the Bottom Sheet
    ///
    @Test func `add given VC view to the bottom sheet subviews`() {
        let viewController = BottomSheetPresentableViewController()
        let bottomSheet = BottomSheetViewController(childViewController: viewController)

        bottomSheet.viewDidLoad()

        #expect(bottomSheet.view.subviews.flatMap { $0.subviews }.contains(viewController.view))
    }
}

private class BottomSheetPresentableViewController: UIViewController, DrawerPresentable {
    var initialHeight: CGFloat = 0
}
