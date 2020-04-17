import UIKit

extension BottomSheetListSelectorViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        let bottomSheetHeight = fullBottomSheetHeight
        let halfViewHeight = view.bounds.height / 0.5
        return (bottomSheetHeight > halfViewHeight) ? .topMargin(halfViewHeight): .contentHeight(bottomSheetHeight)
    }

    var expandedHeight: DrawerHeight {
        return .contentHeight(fullBottomSheetHeight)
    }
}

private extension BottomSheetListSelectorViewController {
    var fullBottomSheetHeight: CGFloat {
        guard let tableView = tableView else {
            return 0
        }
        tableView.layoutIfNeeded()
        let size = tableView.contentSize
        let height = size.height + BottomSheetViewController.Constants.additionalContentTopMargin
        return height
    }
}
