import SwiftUI

// MARK: - Point of Sale Barcode Scanner Setup Flow Manager
@available(iOS 17.0, *)
@Observable
class PointOfSaleBarcodeScannerSetupFlowManager {
    var currentState: PointOfSaleBarcodeScannerSetupFlowState = .scannerSelection
    @ObservationIgnored @Binding var isPresented: Bool
    private var currentFlow: PointOfSaleBarcodeScannerFlow?

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    func selectScanner(_ scannerType: ScannerType) {
        currentFlow = PointOfSaleBarcodeScannerFlow(scannerType: scannerType, onComplete: { [weak self] in
            self?.isPresented = false
        }, onBackToSelection: { [weak self] in
            self?.goBackToSelection()
        })
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

    func isComplete() -> Bool {
        currentFlow?.isComplete ?? false
    }

    var buttonConfiguration: ButtonConfiguration {
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
}