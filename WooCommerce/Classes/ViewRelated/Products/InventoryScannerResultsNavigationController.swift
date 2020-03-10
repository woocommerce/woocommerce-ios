import PanModal
import UIKit
import Yosemite

final class InventoryScannerResultsNavigationController: UINavigationController {
    private let scannedProductsViewController = ScannedProductsViewController()

    private(set) var isPresented: Bool = false

    init() {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [scannedProductsViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func present(by viewController: UIViewController) {
        viewController.presentPanModal(self)
        isPresented = true
    }

    func productScanned(product: Product) {
        scannedProductsViewController.productScanned(product: product)
    }
}

// MARK: - Pan Modal Presentable
extension InventoryScannerResultsNavigationController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return (topViewController as? PanModalPresentable)?.panScrollable
    }

    var panModalBackgroundColor: UIColor {
        return .clear
    }

    var longFormHeight: PanModalHeight {
        return .maxHeight
    }

    var shortFormHeight: PanModalHeight {
        let topInset = view.bounds.height * 0.7
        return .maxHeightWithTopInset(topInset)
    }

    func panModalDidDismiss() {
        isPresented = false
    }
}
