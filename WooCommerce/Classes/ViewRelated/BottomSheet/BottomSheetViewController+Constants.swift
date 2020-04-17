import UIKit

extension BottomSheetViewController.Constants {
    /// The height of the space above the bottom sheet content, including the grip view and space around it.
    ///
    static let additionalContentTopMargin: CGFloat = BottomSheetViewController.Constants.gripHeight
        + BottomSheetViewController.Constants.Header.spacing
        + BottomSheetViewController.Constants.Stack.insets.top
}
