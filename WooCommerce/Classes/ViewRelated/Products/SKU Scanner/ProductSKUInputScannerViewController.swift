import UIKit

/// Container view controller of barcode scanner for product SKU input.
final class ProductSKUInputScannerViewController: UIViewController {
    private lazy var barcodeScannerChildViewController: BarcodeScannerViewController = {
        let viewProperties = BarcodeScannerViewController.ViewProperties(instructionText: Localization.instructionText)
        return BarcodeScannerViewController(viewProperties: viewProperties) { [weak self] result in
            guard let barcode = try? result.get().first else {
                return
            }
            self?.onBarcodeScanned(barcode)
        }
    }()

    private let onBarcodeScanned: (String) -> Void

    init(onBarcodeScanned: @escaping (String) -> Void) {
        self.onBarcodeScanned = onBarcodeScanned
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

private extension ProductSKUInputScannerViewController {
    func configureNavigation() {
        title = NSLocalizedString("Scan barcode to update SKU", comment: "Navigation bar title for scanning a barcode to use as a product's SKU.")
    }

    func configureBarcodeScannerChildViewController() {
        guard let contentView = barcodeScannerChildViewController.view else {
            return
        }
        addChild(barcodeScannerChildViewController)
        view.addSubview(contentView)
        barcodeScannerChildViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)
    }
}

private extension ProductSKUInputScannerViewController {
    enum Localization {
        static let instructionText = NSLocalizedString("Scan product barcode",
                                                       comment: "The instruction text below the scan area in the barcode scanner for product SKU.")
    }
}
