import FloatingPanel
import UIKit
import Yosemite

final class InventoryScannerResultsNavigationController: UINavigationController {
    private let scannedProductsViewController = ScannedProductsViewController()
    private lazy var floatingPanelController: FloatingPanelController = {
        let fpc = FloatingPanelController(delegate: self)
        fpc.set(contentViewController: self)
        return fpc
    }()

    private var isPresented: Bool = false

    init() {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [scannedProductsViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func present(by viewController: UIViewController) {
        guard isPresented == false else {
            floatingPanelController.move(to: .half, animated: true)
            return
        }

        viewController.present(floatingPanelController, animated: true, completion: nil)
        isPresented = true
    }

    func productScanned(product: Product) {
        scannedProductsViewController.productScanned(product: product)
    }
}

extension InventoryScannerResultsNavigationController: FloatingPanelControllerDelegate {

}
