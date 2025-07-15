import SwiftUI

// MARK: - Point of Sale Barcode Scanner Setup Flow
@available(iOS 17.0, *)
@Observable
class PointOfSaleBarcodeScannerSetupFlow {
    private let scannerType: PointOfSaleBarcodeScannerType
    private let onComplete: () -> Void
    private let onBackToSelection: () -> Void
    private var flowSteps: [PointOfSaleBarcodeScannerStepID: PointOfSaleBarcodeScannerSetupStep] = [:]
    private var currentStepKey: PointOfSaleBarcodeScannerStepID = .start

    init(scannerType: PointOfSaleBarcodeScannerType,
         onComplete: @escaping () -> Void,
         onBackToSelection: @escaping () -> Void) {
        self.scannerType = scannerType
        self.onComplete = onComplete
        self.onBackToSelection = onBackToSelection
        self.flowSteps = createFlowSteps(for: scannerType)
    }

    var currentStep: PointOfSaleBarcodeScannerSetupStep? {
        flowSteps[currentStepKey]
    }

    var isComplete: Bool {
        currentStepKey == .complete
    }

    var nextButtonTitle: String {
        isComplete ? Localization.doneButtonTitle : Localization.nextButtonTitle
    }

    func nextStep() {
        transition(to: .next)
    }

    func previousStep() {
        transition(to: .back) { [weak self] in
            // If no back transition is defined, go back to selection
            self?.onBackToSelection()
        }
    }

    func restartFlow() {
        currentStepKey = .start
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
                    if self?.isComplete == true {
                        self?.onComplete()
                    } else {
                        self?.nextStep()
                    }
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
              let targetStep = currentStep.transitions[transitionType] else {
            fallback?()
            return
        }

        currentStepKey = targetStep
    }

    private func createFlowSteps(for scannerType: PointOfSaleBarcodeScannerType) -> [PointOfSaleBarcodeScannerStepID: PointOfSaleBarcodeScannerSetupStep] {
        switch scannerType {
        case .socketS720:
            return [
                .start: createWelcomeStep(title: "Socket S720 Setup")
                // TODO: Add more steps for Socket S720 WOOMOB-698
            ]
        case .starBSH20B:
            return [
                .start: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerBarcodeView(
                            title: String(format: Localization.starSetUpBarcodeStepTitleFormat, scannerType.name),
                            instruction: Localization.setUpBarcodeStepInstruction,
                            barcode: .starBsh20SetupBarcode)
                    },
                    transitions: [
                        .next: .pairing
                    ]
                ),
                .pairing: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerPairingView(scanner: scannerType)
                    },
                    transitions: [
                        .next: .test,
                        .back: .start
                    ]
                ),
                .test: PointOfSaleBarcodeScannerSetupStep(
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
                        .next: .complete,
                        .error: .testFailed,
                        .back: .pairing
                    ]
                ),
                .complete: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerSetupCompleteView()
                    },
                    buttonCustomization: PointOfSaleBarcodeScannerOptionalScannerInformationButtonCustomization(),
                    transitions: [
                        .next: .information,
                    ]),
                .testFailed: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerErrorView()
                    },
                    buttonCustomization: PointOfSaleBarcodeScannerErrorButtonCustomization(),
                    transitions: [
                        .retry: .start,
                        .back: .test
                    ]
                ),
                .information: PointOfSaleBarcodeScannerSetupStep(
                    content: { ProductBarcodeSetupInformation() },
                    buttonCustomization: PointOfSaleBarcodeScannerNoButtonsButtonCustomization()
                )
            ]
        case .tbcScanner:
            return [
                .start: createWelcomeStep(title: "TBC Scanner Setup")
                // TODO: Add more steps for TBC Scanner WOOMOB-699
            ]
        case .other:
            return [
                .start: PointOfSaleBarcodeScannerSetupStep(
                    content: { BarcodeScannerInformation() },
                    transitions: [.next: .information]
                ),
                .information: PointOfSaleBarcodeScannerSetupStep(
                    content: { ProductBarcodeSetupInformation() },
                    buttonCustomization: PointOfSaleBarcodeScannerBackOnlyButtonCustomization(),
                    transitions: [.back: .start]
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

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerOptionalScannerInformationButtonCustomization: PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration {
        return PointOfSaleFlowButtonConfiguration(
            primaryButton: nil,
            secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: Localization.informationButtonTitle,
                action: { flow.transition(to: .next) }
            )
        )
    }

    private enum Localization {
        static let informationButtonTitle = "How to set up barcodes on products"
    }
}

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerNoButtonsButtonCustomization: PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration {
        return PointOfSaleFlowButtonConfiguration.noButtons()
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
