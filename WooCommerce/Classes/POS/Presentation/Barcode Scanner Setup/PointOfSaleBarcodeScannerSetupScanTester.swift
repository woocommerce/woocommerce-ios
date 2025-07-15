import Foundation

struct PointOfSaleBarcodeScannerSetupScanTester {
    private let onTestPass: () -> Void
    private let onTestFailure: () -> Void
    private let barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode

    init(onTestPass: @escaping () -> Void, onTestFailure: @escaping () -> Void, barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode) {
        self.onTestPass = onTestPass
        self.onTestFailure = onTestFailure
        self.barcodeDefinition = barcodeDefinition
    }

    var barcode: PointOfSaleAssets {
        barcodeDefinition.barcodeAsset
    }

    func handleScan(_ scanResult: Result<String, Error>) {
        switch scanResult {
        case .success(barcodeDefinition.expectedValue):
            onTestPass()
        case .success, .failure:
            onTestFailure()
        }
    }
}
