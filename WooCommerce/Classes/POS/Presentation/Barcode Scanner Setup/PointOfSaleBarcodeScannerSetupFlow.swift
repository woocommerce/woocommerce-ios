import SwiftUI

// MARK: - Point of Sale Barcode Scanner Setup Flow
@available(iOS 17.0, *)
@Observable
class PointOfSaleBarcodeScannerSetupFlow {
    private let scannerType: PointOfSaleBarcodeScannerType
    private let onComplete: () -> Void
    private let onBackToSelection: () -> Void
    private var currentStepIndex: Int = 0

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
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        } else {
            onComplete()
        }
    }

    func previousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
        } else {
            onBackToSelection()
        }
    }

    func restartFlow() {
        currentStepIndex = 0
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

    private var steps: [PointOfSaleBarcodeScannerSetupStep] {
        switch scannerType {
        case .socketS720:
            return [
                createWelcomeStep(title: "Socket S720 Setup")
                // TODO: Add more steps for Socket S720 WOOMOB-698
            ]
        case .starBSH20B:
            return [
                PointOfSaleBarcodeScannerSetupStep(content: {
                    PointOfSaleBarcodeScannerBarcodeView(
                        title: String(format: Localization.starSetUpBarcodeStepTitleFormat, scannerType.name),
                        instruction: Localization.setUpBarcodeStepInstruction,
                        barcode: .starBsh20SetupBarcode)
                }),
                PointOfSaleBarcodeScannerSetupStep(content: {
                    PointOfSaleBarcodeScannerPairingView(scanner: scannerType)
                }),
                PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerTestBarcodeView(
                            scanTester: PointOfSaleBarcodeScannerSetupScanTester(
                                onTestPass: { [weak self] in
                                    self?.nextStep()
                                },
                                onTestFailure: {},
                                barcodeDefinition: .ean13)
                        )
                    },
                    buttonCustomization: PointOfSaleBarcodeScannerBackOnlyButtonCustomization()
                )
                // TODO: Add more steps for Star BSH-20B WOOMOB-696
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
