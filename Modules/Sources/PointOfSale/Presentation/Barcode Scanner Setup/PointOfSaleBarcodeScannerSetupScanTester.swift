import Foundation

@Observable
class PointOfSaleBarcodeScannerSetupScanTester {
    private let onTestPass: () -> Void
    private let onTestFailure: (String) -> Void
    private let onTestTimeout: () -> Void
    private let barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode
    private var timer: Timer?

    init(onTestPass: @escaping () -> Void,
         onTestFailure: @escaping (String) -> Void,
         onTestTimeout: @escaping () -> Void,
         barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode) {
        self.onTestPass = onTestPass
        self.onTestFailure = onTestFailure
        self.onTestTimeout = onTestTimeout
        self.barcodeDefinition = barcodeDefinition
    }

    var barcode: PointOfSaleAssets {
        barcodeDefinition.barcodeAsset
    }

    func handleScan(_ scanResult: Result<String, HIDBarcodeParserError>) {
        switch scanResult {
        case .success(barcodeDefinition.expectedValue):
            onTestPass()
        case .success(let scannedValue):
            onTestFailure(scannedValue)
        case .failure(let error):
            onTestFailure(error.barcode)
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.onTestTimeout()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
