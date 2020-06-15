import UIKit
import WordPressUI

extension BottomSheetListSelectorViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        let height = min(view.frame.height * 0.5, fullBottomSheetHeight)
        return .contentHeight(height)
    }

//    var scrollableView: UIScrollView? {
//        return tableView
//    }

    var expandedHeight: DrawerHeight {
        return .contentHeight(fullBottomSheetHeight)
    }

    // TODO-jc: make these configurable

    var allowsTapToDismiss: Bool {
        return false
    }

    var allowsDragToDismiss: Bool {
        return false
    }

    var dimmingViewBackgroundColor: UIColor {
        .clear
//        UIColor(white: 0.0, alpha: 0.5)
    }

    var allowsUserInteractionsOnDimmingView: Bool {
        return false
    }
}

private extension BottomSheetListSelectorViewController {
    var fullBottomSheetHeight: CGFloat {
        let height = contentSize.height + BottomSheetViewController.Constants.additionalContentTopMargin
        return height
    }
}
