import UIKit
import WordPressUI

/// Presents a bottom sheet list selector specified in its initializer.
///
final class BottomSheetListSelectorPresenter<Command: BottomSheetListSelectorCommand> {
    private let bottomSheetChildViewController: DrawerPresentableViewController

    /// - Notable Parameters:
    ///   - onDismiss: Called when the bottom sheet is dismissed. Useful when tapping on each bottom sheet row does not trigger navigation changes.
    init(viewProperties: BottomSheetListSelectorViewProperties,
         command: Command,
         onDismiss: ((_ selected: Command.Model?) -> Void)? = nil) {
        bottomSheetChildViewController = BottomSheetListSelectorViewController(viewProperties: viewProperties,
                                                                               command: command,
                                                                               onDismiss: onDismiss)
    }

    func show(from presenting: UIViewController,
              sourceView: UIView? = nil,
              sourceBarButtonItem: UIBarButtonItem? = nil,
              arrowDirections: UIPopoverArrowDirection = .any) {
        let bottomSheet = BottomSheetViewController(childViewController: bottomSheetChildViewController)
        bottomSheet.show(from: presenting, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem, arrowDirections: arrowDirections)
    }
}
