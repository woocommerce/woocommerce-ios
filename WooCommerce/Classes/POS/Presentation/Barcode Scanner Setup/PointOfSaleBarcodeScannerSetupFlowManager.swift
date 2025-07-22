import SwiftUI
import GameController
import WooFoundation

// MARK: - Point of Sale Barcode Scanner Setup Flow Manager
@available(iOS 17.0, *)
@Observable
class PointOfSaleBarcodeScannerSetupFlowManager {
    var currentState: PointOfSaleBarcodeScannerSetupFlowState = .scannerSelection
    @ObservationIgnored @Binding var isPresented: Bool
    private var currentFlow: PointOfSaleBarcodeScannerSetupFlow?
    private let analytics: Analytics
    private var keyboardObserver: NSObjectProtocol?

    init(isPresented: Binding<Bool>, analytics: Analytics = ServiceLocator.analytics) {
        self._isPresented = isPresented
        self.analytics = analytics
        setupKeyboardObserver()
    }

    deinit {
        removeKeyboardObserver()
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
                self?.isPresented = false
            }
        )
        currentState = .setupFlow(scannerType)
    }

    func goBackToSelection() {
        currentState = .scannerSelection
        currentFlow = nil
    }

    func nextStep() {
        currentFlow?.nextStep()
    }

    func previousStep() {
        currentFlow?.previousStep()
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
            self?.handleKeyboardConnected()
        }
    }

    private func removeKeyboardObserver() {
        if let keyboardObserver = keyboardObserver {
            NotificationCenter.default.removeObserver(keyboardObserver)
            self.keyboardObserver = nil
        }
    }

    private func handleKeyboardConnected() {
        guard case .setupFlow(let scannerType) = currentState, let step = getCurrentSetupStepValue() else { return }
        analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupScannerConnected(scanner: scannerType, step: step))
    }
}
