import SwiftUI

// MARK: - Point of Sale Barcode Scanner Setup Flow
@available(iOS 17.0, *)
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

    var isNextButtonEnabled: Bool {
        true
    }

    var shouldShowBackButton: Bool {
        true
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

    func getButtonConfiguration() -> ButtonConfiguration {
        guard let step = currentStep else {
            return .noButtons()
        }

        // Use step customization if available
        if let customization = step.customization {
            return customization.customizeButtons(for: self)
        }

        // Default button configuration
        return ButtonConfiguration(
            shouldShowBackButton: shouldShowBackButton,
            shouldShowNextButton: true,
            nextButtonTitle: nextButtonTitle,
            isNextButtonEnabled: isNextButtonEnabled,
            onBack: { [weak self] in
                self?.previousStep()
            },
            onNext: { [weak self] in
                self?.nextStep()
            }
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
                createWelcomeStep(title: "Star BSH-20B Setup")
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
            content: { ScannerWelcomeView(title: title) },
            customization: PointOfSaleBarcodeScannerWelcomeStepCustomization()
        )
    }
}

// MARK: - Example Step Customizations
@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerWelcomeStepCustomization: PointOfSaleBarcodeScannerStepCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> ButtonConfiguration {
        return .doneOnly {
            flow.nextStep()
        }
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
    }
}
