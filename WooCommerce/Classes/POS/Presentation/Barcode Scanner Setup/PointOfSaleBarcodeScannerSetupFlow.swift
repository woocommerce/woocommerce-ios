import SwiftUI
import WooFoundation

// MARK: - Point of Sale Barcode Scanner Setup Flow
@available(iOS 17.0, *)
@Observable
class PointOfSaleBarcodeScannerSetupFlow {
    private let scannerType: PointOfSaleBarcodeScannerType
    private let onComplete: () -> Void
    private let onBackToSelection: () -> Void
    private var currentStepIndex: Int = 0
    private let analytics: Analytics

    init(scannerType: PointOfSaleBarcodeScannerType,
         onComplete: @escaping () -> Void,
         onBackToSelection: @escaping () -> Void,
         analytics: Analytics = ServiceLocator.analytics) {
        self.scannerType = scannerType
        self.onComplete = onComplete
        self.onBackToSelection = onBackToSelection
        self.analytics = analytics
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
            trackSetupComplete()
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

    func getCurrentAnalyticsStepValue() -> String? {
        return currentStep?.stepType.analyticsValue ?? "setup_barcode"
    }

    private func trackTestScanSuccess() {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupTestScanSuccess(scanner: scannerType))
    }

    private func trackTestScanFailed(scanValue: String) {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupTestScanFailed(scanner: scannerType, scanValue: scanValue))
    }

    private func trackTestScanTimedOut() {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupTestScanTimedOut(scanner: scannerType))
    }

    private func trackSetupNext() {
        if let step = getCurrentAnalyticsStepValue() {
            analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupNextTapped(scanner: scannerType, step: step))
        }
    }

    private func trackSetupBack() {
        if let step = getCurrentAnalyticsStepValue() {
            analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupBackTapped(scanner: scannerType, step: step))
        }
    }

    private func trackSetupComplete() {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupComplete(scanner: scannerType))
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
                    self?.trackSetupNext()
                    self?.nextStep()
                }
            ),
            secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: Localization.backButtonTitle,
                action: { [weak self] in
                    self?.trackSetupBack()
                    self?.previousStep()
                }
            )
        )
    }

    private var steps: [PointOfSaleBarcodeScannerSetupStep] {
        switch scannerType {
        case .socketS720:
            return [
                createWelcomeStep(title: "Socket S720 Setup", stepType: .setupBarcode)
                // TODO: Add more steps for Socket S720 WOOMOB-698
            ]
        case .starBSH20B:
            return [
                PointOfSaleBarcodeScannerSetupStep(stepType: .setupBarcode, content: {
                    PointOfSaleBarcodeScannerBarcodeView(
                        title: String(format: Localization.starSetUpBarcodeStepTitleFormat, scannerType.name),
                        instruction: Localization.setUpBarcodeStepInstruction,
                        barcode: .starBsh20SetupBarcode)
                }),
                PointOfSaleBarcodeScannerSetupStep(stepType: .pairing, content: {
                    PointOfSaleBarcodeScannerPairingView(scanner: scannerType)
                }),
                PointOfSaleBarcodeScannerSetupStep(
                    stepType: .testBarcode,
                    content: { [weak self] in
                        guard let self else { return EmptyView() }
                        return PointOfSaleBarcodeScannerTestBarcodeView(
                            scanTester: self.createScanTester(barcodeDefinition: .ean13)
                        )
                    },
                    buttonCustomization: PointOfSaleBarcodeScannerBackOnlyButtonCustomization()
                ),
                PointOfSaleBarcodeScannerSetupStep(
                    stepType: .complete,
                    content: {
                        PointOfSaleBarcodeScannerSetupCompleteView()
                    })
                // TODO: Add optional error step and documentation step for Star BSH-20B WOOMOB-696
                // TODO: Track barcodeScannerSetupRetryTapped
            ]
        case .tbcScanner:
            return [
                createWelcomeStep(title: "TBC Scanner Setup", stepType: .setupBarcode)
                // TODO: Add more steps for TBC Scanner WOOMOB-699
            ]
        case .other:
            return [
                PointOfSaleBarcodeScannerSetupStep(
                    title: "General Scanner Setup",
                    stepType: .setupBarcode,
                    content: { BarcodeScannerInformationContent() }
                )
            ]
        }
    }

    private func createWelcomeStep(title: String, stepType: PointOfSaleBarcodeScannerSetupStepType) -> PointOfSaleBarcodeScannerSetupStep {
        PointOfSaleBarcodeScannerSetupStep(
            title: title,
            stepType: stepType,
            content: { PointOfSaleBarcodeScannerWelcomeView(title: title) },
            buttonCustomization: PointOfSaleBarcodeScannerWelcomeButtonCustomization()
        )
    }

    private func createScanTester(barcodeDefinition: PointOfSaleBarcodeScannerTestBarcode) -> PointOfSaleBarcodeScannerSetupScanTester {
        PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: { [weak self] in
                self?.trackTestScanSuccess()
                self?.nextStep()
            },
            onTestFailure: { [weak self] scanValue in
                self?.trackTestScanFailed(scanValue: scanValue)
            },
            onTestTimeout: { [weak self] in
                self?.trackTestScanTimedOut()
            },
            barcodeDefinition: barcodeDefinition
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
