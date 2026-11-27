import SwiftUI
import GameController
import WooFoundation

// MARK: - Point of Sale Barcode Scanner Setup Flow Manager
@MainActor
@Observable
class PointOfSaleBarcodeScannerSetupFlowManager {
    var currentState: PointOfSaleBarcodeScannerSetupFlowState = .scannerSelection
    @ObservationIgnored @Binding var isPresented: Bool
    @ObservationIgnored var onDismiss: (() -> Void)?
    private var currentFlow: PointOfSaleBarcodeScannerSetupFlow?
    private let analytics: POSAnalyticsProviding
    // Read from the nonisolated deinit; otherwise only set once from `init` on the main actor.
    // Remove `nonisolated(unsafe)` once the deployment target allows `isolated deinit` (iOS 18.4).
    @ObservationIgnored nonisolated(unsafe) private var keyboardObserver: NSObjectProtocol?

    var currentStepKey: String? {
        currentFlow?.currentStepKey.rawValue
    }

    var currentPageID: String {
        currentFlow?.currentStepKey.pageID.rawValue ?? Constants.scannerSelectionPageID
    }

    init(isPresented: Binding<Bool>, analytics: POSAnalyticsProviding) {
        self._isPresented = isPresented
        self.analytics = analytics
        setupKeyboardObserver()
    }

    deinit {
        if let keyboardObserver {
            NotificationCenter.default.removeObserver(keyboardObserver)
        }
    }

    func selectScanner(_ scannerType: PointOfSaleBarcodeScannerType) {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupScannerSelected(scanner: scannerType))

        currentFlow = PointOfSaleBarcodeScannerSetupFlow(
            scannerType: scannerType,
            analytics: analytics,
            onBackToSelection: { [weak self] in
                self?.goBackToSelection()
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )
        currentState = .setupFlow(scannerType)
    }

    private func dismiss() {
        if let onDismiss {
            onDismiss()
        } else {
            isPresented = false
        }
    }

    func goBackToSelection() {
        currentState = .scannerSelection
        currentFlow = nil
    }

    func getCurrentStep() -> PointOfSaleBarcodeScannerSetupStep? {
        currentFlow?.currentStep
    }

    var buttonConfiguration: PointOfSaleFlowButtonConfiguration {
        switch currentState {
        case .scannerSelection:
            return .noButtons()
        case .setupFlow:
            guard let flow = currentFlow else {
                return .noButtons()
            }

            return flow.getButtonConfiguration()
        }
    }

    func onDisappear() {
        if case .setupFlow(let scannerType) = currentState, let step = getCurrentSetupStepValue() {
            analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupDismissed(scanner: scannerType, step: step))
        } else {
            analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupDismissed())
        }
    }

    private func getCurrentSetupStepValue() -> String? {
        return currentFlow?.getCurrentAnalyticsStepValue()
    }

    private func setupKeyboardObserver() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // `queue: .main` delivers the notification on the main thread.
            MainActor.assumeIsolated {
                self?.handleKeyboardConnected()
            }
        }
    }

    private func handleKeyboardConnected() {
        guard case .setupFlow(let scannerType) = currentState else { return }
        analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupScannerConnected(scanner: scannerType))
    }

    private enum Constants {
        static let scannerSelectionPageID = "scannerSelection"
    }
}
