import Combine
import UIKit

/// Container view controller of barcode scanner for product SKU input.
final class ProductSKUInputScannerViewController: UIViewController {
    private lazy var barcodeScannerChildViewController: BarcodeScannerViewController = BarcodeScannerViewController(instructionText: Localization.instructionText)

    private let onBarcodeScanned: (String) -> Void

    private var cancellables: Set<AnyCancellable> = []

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
        observeTheFirstBarcode()
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

    func observeTheFirstBarcode() {
        barcodeScannerChildViewController.scannedBarcodes
            .compactMap { $0.first }
            .first()
            .sink { [weak self] barcode in
                self?.onBarcodeScanned(barcode)
            }
            .store(in: &cancellables)
    }
}

private extension ProductSKUInputScannerViewController {
    enum Localization {
        static let title = NSLocalizedString("Scan barcode to update SKU", comment: "Navigation bar title for scanning a barcode to use as a product's SKU.")
        static let instructionText = NSLocalizedString("Scan product barcode",
                                                       comment: "The instruction text below the scan area in the barcode scanner for product SKU.")
    }
}
