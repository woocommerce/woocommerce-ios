import UIKit

/// Container view controller of barcode scanner for product SKU input.
final class QRCodeLoginScannerViewController: UIViewController {
    private lazy var barcodeScannerChildViewController: BarcodeScannerViewController = {
        return BarcodeScannerViewController(instructionText: Localization.instructionText) { [weak self] result in
            guard let self = self else { return }
            guard self.hasDetectedBarcode == false else {
                return
            }
            guard let barcode = try? result.get().first else {
                return
            }
            self.hasDetectedBarcode = true
            self.onBarcodeScanned(barcode)
        }
    }()

    private let onBarcodeScanned: (String) -> Void

    /// Tracks whether a barcode has been detected because the barcode detection callback is only handled once.
    private var hasDetectedBarcode: Bool = false

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

private extension QRCodeLoginScannerViewController {
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

private extension QRCodeLoginScannerViewController {
    enum Localization {
        static let title = NSLocalizedString("QR code login", comment: "Navigation bar title for scanning a QR code to log in.")
        static let instructionText = NSLocalizedString("From your store's inbox, click on the QR code link and scan the QR code to log in",
                                                       comment: "The instruction text below the scan area in the QR code scanner to log in.")
    }
}
