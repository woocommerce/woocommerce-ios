import UIKit
import Yosemite

final class InventoryScannerResultsNavigationController: UINavigationController {
    private lazy var scannedProductsViewController: ScannedProductsViewController = {
        return ScannedProductsViewController { [weak self] in
            self?.onSaveCompletion()
        }
    }()
    
    private let onSaveCompletion: () -> Void

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
