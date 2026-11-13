import SwiftUI
import UIKit

/// Container view controller of barcode scanner.
final class ScannerContainerViewController: UIViewController {
    private lazy var barcodeScannerChildViewController: CodeScannerViewController = {
        return CodeScannerViewController(instructionText: instructionText,
                                            format: .barcode { [weak self] result in
            self?.handleBarcodeDetectionResult(result)
        })
    }()

    private let onBarcodeScanned: (ScannedBarcode) -> Void
    private let navigationTitle: String
    private let instructionText: String
    private let offersHardwareScanner: Bool
    private let hardwareBarcodeScanner: HardwareBarcodeScanner
    private var hardwareBarcodeScannerToken: HardwareBarcodeScanner.ListenerToken?

    /// The camera doesn't read codes while the sheet about external scanners is open, like on Android.
    private var isShowingHardwareScannerInfo = false


    /// Tracks whether a barcode has been detected because the barcode detection callback is only handled once.
    private var hasDetectedBarcode: Bool = false
    private var candidateBarcode: ScannedBarcode?
    private var consecutiveDetectionCount = 0

    // Vision samples the camera every 0.1 seconds; three matching samples filter isolated misreads.
    private let requiredConsecutiveDetections = 3

    init(navigationTitle: String,
         instructionText: String,
         offersHardwareScanner: Bool = false,
         hardwareBarcodeScanner: HardwareBarcodeScanner = .shared,
         onBarcodeScanned: @escaping (ScannedBarcode) -> Void) {
        self.navigationTitle = navigationTitle
        self.instructionText = instructionText
        self.offersHardwareScanner = offersHardwareScanner
        self.hardwareBarcodeScanner = hardwareBarcodeScanner
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
        configureHardwareScannerOffer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startListeningForHardwareBarcodes()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForHardwareBarcodes()
    }

    func handleBarcodeDetectionResult(_ result: Result<[ScannedBarcode], Error>) {
        guard !hasDetectedBarcode, !isShowingHardwareScannerInfo else { return }
        guard case let .success(barcodes) = result, let firstBarcode = barcodes.first else {
            candidateBarcode = nil
            consecutiveDetectionCount = 0
            return
        }

        if let candidateBarcode, barcodes.contains(candidateBarcode) {
            consecutiveDetectionCount += 1
        } else {
            candidateBarcode = firstBarcode
            consecutiveDetectionCount = 1
        }

        guard consecutiveDetectionCount >= requiredConsecutiveDetections, let candidateBarcode else { return }
        hasDetectedBarcode = true
        onBarcodeScanned(candidateBarcode)
    }

    /// A scanner sends each code once, so it skips the repeated detections the camera needs.
    func handleHardwareScannedBarcode(_ barcode: ScannedBarcode) {
        guard !hasDetectedBarcode else { return }
        hasDetectedBarcode = true
        onBarcodeScanned(barcode)
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

    func configureHardwareScannerOffer() {
        guard offersHardwareScanner else { return }
        let offerViewController = UIHostingController(rootView: HardwareBarcodeScannerOfferView(
            source: .barcodeScanner,
            onInfoVisibilityChange: { [weak self] isShowing in
                self?.isShowingHardwareScannerInfo = isShowing
            }
        ))
        offerViewController.view.backgroundColor = .clear
        offerViewController.sizingOptions = .intrinsicContentSize
        addChild(offerViewController)
        barcodeScannerChildViewController.addBottomAccessoryView(offerViewController.view)
        offerViewController.didMove(toParent: self)
    }

    func startListeningForHardwareBarcodes() {
        guard offersHardwareScanner, hardwareBarcodeScannerToken == nil else { return }
        hardwareBarcodeScannerToken = hardwareBarcodeScanner.startListening(source: .barcodeScanner, isEnabled: { [weak self] in
            self?.hasDetectedBarcode == false
        }, onScan: { [weak self] barcode in
            self?.handleHardwareScannedBarcode(barcode)
        })
    }

    func stopListeningForHardwareBarcodes() {
        guard let hardwareBarcodeScannerToken else { return }
        hardwareBarcodeScanner.stopListening(hardwareBarcodeScannerToken)
        self.hardwareBarcodeScannerToken = nil
    }
}
