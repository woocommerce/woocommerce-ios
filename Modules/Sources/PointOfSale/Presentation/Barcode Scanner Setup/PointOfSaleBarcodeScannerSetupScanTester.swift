import Foundation

@MainActor
@Observable
class PointOfSaleBarcodeScannerSetupScanTester {
    private let onTestPass: () -> Void
    private let onTestFailure: (String) -> Void
    private let onTestTimeout: () -> Void
    private let barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?

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
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Constants.timeout)
            } catch {
                // Cancelled by `stopTimer()`.
                return
            }
            self?.onTestTimeout()
        }
    }

    func stopTimer() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }
}

private extension PointOfSaleBarcodeScannerSetupScanTester {
    enum Constants {
        static let timeout: Duration = .seconds(10)
    }
}
