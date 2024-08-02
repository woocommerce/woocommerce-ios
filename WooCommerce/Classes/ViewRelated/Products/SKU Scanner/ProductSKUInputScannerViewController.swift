import UIKit

/// Container view controller of barcode scanner for product SKU input.
final class ProductSKUInputScannerViewController: UIViewController {
    private lazy var barcodeScannerChildViewController: CodeScannerViewController = {
        return CodeScannerViewController(instructionText: Localization.instructionText,
                                            format: .barcode { [weak self] result in
            guard let self = self else { return }
            guard self.hasDetectedBarcode == false else {
                return
            }
            guard let barcode = try? result.get().first else {
                return
            }
            self.hasDetectedBarcode = true
            self.onBarcodeScanned(barcode)
        })
    }()

    private let onBarcodeScanned: (ScannedBarcode) -> Void

    /// Tracks whether a barcode has been detected because the barcode detection callback is only handled once.
    private var hasDetectedBarcode: Bool = false

    init(onBarcodeScanned: @escaping (ScannedBarcode) -> Void) {
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
        title = Localization.title
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
        static let title = NSLocalizedString("ProductSKUInputScanner.titleView",
                                             value: "Scan barcode or QR Code to update SKU",
                                             comment: "Navigation bar title for scanning a barcode or QR Code to use as a product's SKU.")
        static let instructionText = NSLocalizedString("ProductSKUInputScanner.instructionText",
                                                       value: "Scan product barcode or QR Code",
                                                       comment: "The instruction text below the scan area in the barcode scanner for product SKU.")
    }
}
