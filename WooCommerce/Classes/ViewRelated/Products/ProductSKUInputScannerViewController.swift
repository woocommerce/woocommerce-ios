import UIKit

final class ProductSKUInputScannerViewController: UIViewController {

    private lazy var barcodeScannerChildViewController : BarcodeScannerViewController = {
        return BarcodeScannerViewController { [weak self] (barcodes, error) in
            guard let barcode = barcodes.first else {
                return
            }
            self?.onBarcodeScanned(barcode)
        }
    }()

    private lazy var throttler: Throttler = Throttler(seconds: 1)

    private let onBarcodeScanned: (String) -> Void
    private let onCancelled: () -> Void

    init(onBarcodeScanned: @escaping (String) -> Void,
         onCancelled: @escaping () -> Void) {
        self.onBarcodeScanned = onBarcodeScanned
        self.onCancelled = onCancelled
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

// MARK: Navigation
//
private extension ProductSKUInputScannerViewController {
    @objc func cancelButtonTapped() {
        onCancelled()
    }
}

private extension ProductSKUInputScannerViewController {
    func configureNavigation() {
        title = NSLocalizedString("Scan barcode for SKU", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }

    func configureBarcodeScannerChildViewController() {
        let contentView = barcodeScannerChildViewController.view!
        addChild(barcodeScannerChildViewController)
        view.addSubview(contentView)
        barcodeScannerChildViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)
    }
}
