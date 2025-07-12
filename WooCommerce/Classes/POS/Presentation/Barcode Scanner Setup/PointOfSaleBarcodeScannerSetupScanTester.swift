import Foundation

struct PointOfSaleBarcodeScannerSetupScanTester {
    private let onTestPass: () -> Void
    private let onTestFailure: (String) -> Void
    private let onTestTimeout: () -> Void
    private let barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode

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

    func handleScan(_ scanResult: Result<String, Error>) {
        switch scanResult {
        case .success(barcodeDefinition.expectedValue):
            onTestPass()
        case .success(let scannedValue):
            onTestFailure(scannedValue)
        case .failure(HIDBarcodeParserError.scanTooShort(barcode: let scannedValue)):
            onTestFailure(scannedValue)
        case .failure(HIDBarcodeParserError.timedOut(barcode: let scannedValue)):
            onTestFailure(scannedValue)
        case .failure:
            onTestFailure("")
        }
    }

    func handleScanTimeout() {
        onTestTimeout()
    }
}
