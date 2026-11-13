import Foundation
import Observation
import protocol WooFoundation.Analytics

@MainActor
@Observable
final class HardwareBarcodeScannerInfoViewModel {
    enum TestScanState: Equatable {
        case waiting
        case missingEnterSuffix
        case wrongValue
        case success
    }

    static let testBarcode = "1234567890128"

    private(set) var testScanState: TestScanState = .waiting

    @ObservationIgnored private let source: WooAnalyticsEvent.BarcodeScanning.Source
    @ObservationIgnored private let analytics: Analytics
    @ObservationIgnored private let hardwareBarcodeScanner: HardwareBarcodeScanner
    @ObservationIgnored private let sleep: @Sendable (Duration) async throws -> Void
    @ObservationIgnored private let onDismiss: () -> Void
    @ObservationIgnored private var listenerToken: HardwareBarcodeScanner.ListenerToken?
    @ObservationIgnored private(set) var dismissTask: Task<Void, Never>?

    init(source: WooAnalyticsEvent.BarcodeScanning.Source,
         analytics: Analytics = ServiceLocator.analytics,
         hardwareBarcodeScanner: HardwareBarcodeScanner = .shared,
         sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
         onDismiss: @escaping () -> Void) {
        self.source = source
        self.analytics = analytics
        self.hardwareBarcodeScanner = hardwareBarcodeScanner
        self.sleep = sleep
        self.onDismiss = onDismiss
    }

    /// The sheet takes every scan while it is shown, so a test scan doesn't reach the screen below it.
    func onAppear() {
        guard listenerToken == nil else { return }
        listenerToken = hardwareBarcodeScanner.startListening(source: source, onMissingEnterSuffix: { [weak self] in
            self?.handleMissingEnterSuffix()
        }, onScan: { [weak self] scannedBarcode in
            self?.handleScan(scannedBarcode.payloadStringValue)
        })
    }

    func onDisappear() {
        if let listenerToken {
            hardwareBarcodeScanner.stopListening(listenerToken)
            self.listenerToken = nil
        }
        dismissTask?.cancel()
        dismissTask = nil
    }

    func handleScan(_ barcode: String) {
        guard testScanState != .success else { return }
        guard barcode == Self.testBarcode else {
            testScanState = .wrongValue
            analytics.track(event: .BarcodeScanning.hardwareBarcodeScannerTestScanFailed(from: source, failure: .wrongValue))
            return
        }
        testScanState = .success
        analytics.track(event: .BarcodeScanning.hardwareBarcodeScannerTestScanSuccess(from: source))
        dismissTask = Task { [weak self, sleep] in
            do {
                try await sleep(Constants.successDisplayDuration)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.onDismiss()
        }
    }

    func handleMissingEnterSuffix() {
        guard testScanState != .success else { return }
        testScanState = .missingEnterSuffix
        analytics.track(event: .BarcodeScanning.hardwareBarcodeScannerTestScanFailed(from: source, failure: .missingEnterSuffix))
    }
}

private extension HardwareBarcodeScannerInfoViewModel {
    enum Constants {
        static let successDisplayDuration: Duration = .seconds(3)
    }
}
