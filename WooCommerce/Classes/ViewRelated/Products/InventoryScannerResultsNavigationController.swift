import UIKit
import WordPressUI
import Yosemite

extension InventoryScannerResultsNavigationController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .contentHeight(fullBottomSheetHeight)
    }

    var expandedHeight: DrawerHeight {
        return .contentHeight(fullBottomSheetHeight)
    }
}

private extension InventoryScannerResultsNavigationController {
    var fullBottomSheetHeight: CGFloat {
        let height = contentSize.height + BottomSheetViewController.Constants.additionalContentTopMargin
        return height
    }
}

final class InventoryScannerResultsNavigationController: UINavigationController {
    private lazy var scannedProductsViewController: ScannedProductsViewController = {
        return ScannedProductsViewController { [weak self] in
            self?.onSaveCompletion()
        }
    }()
    
    private let onSaveCompletion: () -> Void

    /// Used for calculating the full content height in `DrawerPresentable` implementation.
    var contentSize: CGSize {
        return scannedProductsViewController.contentSize
    }

    init(onSaveCompletion: @escaping () -> Void) {
        self.onSaveCompletion = onSaveCompletion
        super.init(nibName: nil, bundle: nil)
        viewControllers = [scannedProductsViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func productScanned(product: Product) {
        scannedProductsViewController.productScanned(product: product)
    }
}
