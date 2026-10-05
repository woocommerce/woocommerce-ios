import Foundation

@MainActor
@Observable
class PointOfSaleBarcodeScannerSetupScanTester {
    private let onTestPass: () -> Void
    private let onTestFailure: (String) -> Void
    private let onTestTimeout: () -> Void
    private let barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode
    private let timeout: Duration
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?

    init(onTestPass: @escaping () -> Void,
         onTestFailure: @escaping (String) -> Void,
         onTestTimeout: @escaping () -> Void,
         barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode,
         timeout: Duration = .seconds(10)) {
        self.onTestPass = onTestPass
        self.onTestFailure = onTestFailure
        self.onTestTimeout = onTestTimeout
        self.barcodeDefinition = barcodeDefinition
        self.timeout = timeout
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
        timeoutTask = Task { [weak self, timeout] in
            do {
                try await Task.sleep(for: timeout)
            } catch {
                // Cancelled by `stopTimer()`.
                return
            }
            // The sleep can finish before a `stopTimer()` that runs while this task waits for the main actor.
            guard !Task.isCancelled else { return }
            self?.onTestTimeout()
        }
    }

    func stopTimer() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }
}
