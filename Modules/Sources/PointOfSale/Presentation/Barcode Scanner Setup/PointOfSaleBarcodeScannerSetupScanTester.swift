import Foundation

@MainActor
@Observable
class PointOfSaleBarcodeScannerSetupScanTester {
    private let onTestPass: () -> Void
    private let onTestFailure: (String) -> Void
    private let onTestTimeout: () -> Void
    private let barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode
    private let sleep: @Sendable (Duration) async throws -> Void
    @ObservationIgnored private(set) var timeoutTask: Task<Void, Never>?

    init(onTestPass: @escaping () -> Void,
         onTestFailure: @escaping (String) -> Void,
         onTestTimeout: @escaping () -> Void,
         barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode,
         sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.onTestPass = onTestPass
        self.onTestFailure = onTestFailure
        self.onTestTimeout = onTestTimeout
        self.barcodeDefinition = barcodeDefinition
        self.sleep = sleep
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
        timeoutTask = Task { [weak self, sleep] in
            do {
                try await sleep(Constants.timeout)
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

private extension PointOfSaleBarcodeScannerSetupScanTester {
    enum Constants {
        static let timeout: Duration = .seconds(10)
    }
}
