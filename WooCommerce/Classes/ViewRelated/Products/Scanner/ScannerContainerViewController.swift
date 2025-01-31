import UIKit

/// Container view controller of barcode scanner.
final class ScannerContainerViewController: UIViewController {
    private lazy var barcodeScannerChildViewController: CodeScannerViewController = {
        return CodeScannerViewController(instructionText: instructionText,
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
    private let navigationTitle: String
    private let instructionText: String


    /// Tracks whether a barcode has been detected because the barcode detection callback is only handled once.
    private var hasDetectedBarcode: Bool = false

    init(navigationTitle: String, instructionText: String, onBarcodeScanned: @escaping (ScannedBarcode) -> Void) {
        self.navigationTitle = navigationTitle
        self.instructionText = instructionText
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

private extension ScannerContainerViewController {
    func configureNavigation() {
        title = navigationTitle
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
