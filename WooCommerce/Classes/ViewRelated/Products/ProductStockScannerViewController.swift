import UIKit
import Yosemite

final class ProductStockScannerViewController: UIViewController {

    private lazy var barcodeScannerChildViewController : BarcodeScannerViewController = {
        return BarcodeScannerViewController { [weak self] (barcodes, error) in
            guard let barcode = barcodes.first else {
                return
            }
            self?.searchProductBySKU(barcode: barcode)
        }
    }()

    private lazy var resultsNavigationController: InventoryScannerResultsNavigationController = {
        return InventoryScannerResultsNavigationController { [weak self] in
            self?.cancelButtonTapped()
        }
    }()

    private lazy var throttler: Throttler = Throttler(seconds: 1)

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureBarcodeScannerChildViewController()
    }
}

// MARK: Search
//
private extension ProductStockScannerViewController {
    func searchProductBySKU(barcode: String) {
        throttler.throttle {
            DispatchQueue.main.async {
                let action = ProductAction.searchProductBySKU(siteID: self.siteID, sku: barcode) { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .success(let product):
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)

                        self.resultsNavigationController.present(by: self)
                        self.resultsNavigationController.productScanned(product: product)
                    case .failure(let error):
                        print("No product matched: \(error)")
                    }
                }
                ServiceLocator.stores.dispatch(action)
            }
        }
    }
}

// MARK: Navigation
//
private extension ProductStockScannerViewController {
    @objc func cancelButtonTapped() {
        if resultsNavigationController.isPresented {
            resultsNavigationController.dismiss(animated: true) {
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

private extension ProductStockScannerViewController {
    func configureNavigation() {
        title = NSLocalizedString("Inventory scanner", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }
}

private extension ProductStockScannerViewController {
    func configureBarcodeScannerChildViewController() {
        let contentView = barcodeScannerChildViewController.view!
        addChild(barcodeScannerChildViewController)
        view.addSubview(contentView)
        barcodeScannerChildViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)
    }
}
