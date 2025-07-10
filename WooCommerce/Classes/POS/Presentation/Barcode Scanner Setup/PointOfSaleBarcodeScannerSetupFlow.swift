import SwiftUI

// MARK: - Point of Sale Barcode Scanner Setup Flow
@available(iOS 17.0, *)
@Observable
class PointOfSaleBarcodeScannerSetupFlow {
    private let scannerType: PointOfSaleBarcodeScannerType
    private let onComplete: () -> Void
    private let onBackToSelection: () -> Void
    private var currentStepIndex: Int = 0
    private var stepHistory: [Int] = []

    init(scannerType: PointOfSaleBarcodeScannerType,
         onComplete: @escaping () -> Void,
         onBackToSelection: @escaping () -> Void) {
        self.scannerType = scannerType
        self.onComplete = onComplete
        self.onBackToSelection = onBackToSelection
    }

    var currentStep: PointOfSaleBarcodeScannerSetupStep? {
        steps[safe: currentStepIndex]
    }

    var isComplete: Bool {
        currentStepIndex >= steps.count - 1
    }

    var nextButtonTitle: String {
        isComplete ? Localization.doneButtonTitle : Localization.nextButtonTitle
    }

    func nextStep() {
        transition(to: .next) { [weak self] in
            // Default behavior: move to next step in array
            if self?.currentStepIndex ?? 0 < (self?.steps.count ?? 0) - 1 {
                self?.stepHistory.append(self?.currentStepIndex ?? 0)
                self?.currentStepIndex = (self?.currentStepIndex ?? 0) + 1
            } else {
                self?.onComplete()
            }
        }
    }

    func previousStep() {
        transition(to: .back) { [weak self] in
            // Default behavior: go back to previous step in history
            if let previousIndex = self?.stepHistory.popLast() {
                self?.currentStepIndex = previousIndex
            } else {
                self?.onBackToSelection()
            }
        }
    }

    func restartFlow() {
        currentStepIndex = 0
        stepHistory.removeAll()
    }

    // MARK: - Generic Transition Methods

    func transition(to transitionType: PointOfSaleBarcodeScannerTransitionType) {
        self.transition(to: transitionType, fallback: nil)
    }

    func getButtonConfiguration() -> PointOfSaleFlowButtonConfiguration {
        guard let step = currentStep else {
            return .noButtons()
        }

        // Use step customization if available
        if let customization = step.buttonCustomization {
            return customization.customizeButtons(for: self)
        }

        // Default button configuration
        return PointOfSaleFlowButtonConfiguration(
            primaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: nextButtonTitle,
                action: { [weak self] in
                    self?.nextStep()
                }
            ),
            secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: Localization.backButtonTitle,
                action: { [weak self] in
                    self?.previousStep()
                }
            )
        )
    }

    // MARK: - Private Methods

    private func transition(to transitionType: PointOfSaleBarcodeScannerTransitionType, fallback: (() -> Void)? = nil) {
        guard let currentStep = currentStep,
              let transition = currentStep.transitions[transitionType] else {
            fallback?()
            return
        }

        transitionToStep(transition.to)
    }

    private func transitionToStep(_ newStepIndex: Int) {
        stepHistory.append(currentStepIndex)
        currentStepIndex = newStepIndex

        // If we're completing the flow, call the completion handler
        if newStepIndex > steps.count - 1 {
            onComplete()
        }
    }

    private var steps: [PointOfSaleBarcodeScannerSetupStep] {
        switch scannerType {
        case .socketS720:
            return [
                createWelcomeStep(title: "Socket S720 Setup")
                // TODO: Add more steps for Socket S720 WOOMOB-698
            ]
        case .starBSH20B:
            return [
                PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerBarcodeView(
                            title: String(format: Localization.starSetUpBarcodeStepTitleFormat, scannerType.name),
                            instruction: Localization.setUpBarcodeStepInstruction,
                            barcode: .starBsh20SetupBarcode)
                    },
                    transitions: [
                        .next: PointOfSaleBarcodeScannerTransition(to: 1, type: .next)
                    ]
                ),
                PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerPairingView(scanner: scannerType)
                    },
                    transitions: [
                        .next: PointOfSaleBarcodeScannerTransition(to: 2, type: .next)
                    ]
                ),
                PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerTestBarcodeView(
                            scanTester: PointOfSaleBarcodeScannerSetupScanTester(
                                onTestPass: { [weak self] in
                                    self?.nextStep()
                                },
                                onTestFailure: { [weak self] in
                                    self?.transition(to: .error)
                                },
                                barcodeDefinition: .ean13)
                        )
                    },
                    buttonCustomization: PointOfSaleBarcodeScannerBackOnlyButtonCustomization(),
                    transitions: [
                        .next: PointOfSaleBarcodeScannerTransition(to: 3, type: .next),
                        .error: PointOfSaleBarcodeScannerTransition(to: 4, type: .error)
                    ]
                ),
                PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerSetupCompleteView()
                    }),
                // Error step
                PointOfSaleBarcodeScannerSetupStep(
                    title: "Test Failed",
                    content: {
                        PointOfSaleBarcodeScannerErrorView()
                    },
                    buttonCustomization: PointOfSaleBarcodeScannerErrorButtonCustomization(),
                    transitions: [
                        .retry: PointOfSaleBarcodeScannerTransition(to: 2, type: .retry),
                        .back: PointOfSaleBarcodeScannerTransition(to: 1, type: .back)
                    ]
                )
                // TODO: Add optional error step and documentation step for Star BSH-20B WOOMOB-696
            ]
        case .tbcScanner:
            return [
                createWelcomeStep(title: "TBC Scanner Setup")
                // TODO: Add more steps for TBC Scanner WOOMOB-699
            ]
        case .other:
            return [
                PointOfSaleBarcodeScannerSetupStep(
                    title: "General Scanner Setup",
                    content: { BarcodeScannerInformationContent() }
                )
            ]
        }
    }

    private func createWelcomeStep(title: String) -> PointOfSaleBarcodeScannerSetupStep {
        PointOfSaleBarcodeScannerSetupStep(
            title: title,
            content: { PointOfSaleBarcodeScannerWelcomeView(title: title) },
            buttonCustomization: PointOfSaleBarcodeScannerWelcomeButtonCustomization()
        )
    }
}

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerBackOnlyButtonCustomization: PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration {
        return PointOfSaleFlowButtonConfiguration(
            primaryButton: nil,
            secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: Localization.backButtonTitle,
                action: { flow.previousStep() }
            )
        )
    }

    private enum Localization {
        static let backButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.back.button.title",
            value: "Back",
            comment: "Title for the back button in barcode scanner setup navigation"
        )
    }
}

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerErrorButtonCustomization: PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration {
        return PointOfSaleFlowButtonConfiguration(
            primaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: Localization.retryButtonTitle,
                action: { flow.transition(to: .retry) }
            ),
            secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: Localization.backButtonTitle,
                action: { flow.transition(to: .back) }
            )
        )
    }

    private enum Localization {
        static let retryButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.error.retry.button.title",
            value: "Retry",
            comment: "Title for the retry button in barcode scanner setup error step"
        )
        static let backButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.error.back.button.title",
            value: "Back",
            comment: "Title for the back button in barcode scanner setup error step"
        )
    }
}

// MARK: - Private Localization Extension
@available(iOS 17.0, *)
private extension PointOfSaleBarcodeScannerSetupFlow {
    enum Localization {
        static let doneButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.done.button.title",
            value: "Done",
            comment: "Title for the done button in barcode scanner setup navigation"
        )
        static let nextButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.next.button.title",
            value: "Next",
            comment: "Title for the next button in barcode scanner setup navigation"
        )
        static let backButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.back.button.title",
            value: "Back",
            comment: "Title for the back button in barcode scanner setup navigation"
        )
        //TODO: WOOMOB-792
        static let starSetUpBarcodeStepTitleFormat = "%1$@ Setup"
        static let setUpBarcodeStepInstruction = "Scan the barcode to set up your scanner."
    }
}
