import UIKit
import WordPressUI

extension BottomSheetListSelectorViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .contentHeight(fullBottomSheetHeight)
    }

    var expandedHeight: DrawerHeight {
        return .contentHeight(fullBottomSheetHeight)
    }
}

private extension BottomSheetListSelectorViewController {
    var fullBottomSheetHeight: CGFloat {
        let height = contentSize.height + BottomSheetViewController.Constants.additionalContentTopMargin
        return height
    }
}
