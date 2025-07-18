import SwiftUI
import WooFoundation

// MARK: - Point of Sale Barcode Scanner Setup Flow
@available(iOS 17.0, *)
@Observable
class PointOfSaleBarcodeScannerSetupFlow {
    private let scannerType: PointOfSaleBarcodeScannerType
    private let onBackToSelection: () -> Void
    private var flowSteps: [PointOfSaleBarcodeScannerStepID: PointOfSaleBarcodeScannerSetupStep] = [:]
    private var currentStepKey: PointOfSaleBarcodeScannerStepID = .setupBarcodeHID
    private let analytics: Analytics

    init(scannerType: PointOfSaleBarcodeScannerType,
         analytics: Analytics = ServiceLocator.analytics,
         onBackToSelection: @escaping () -> Void) {
        self.scannerType = scannerType
        self.analytics = analytics
        self.onBackToSelection = onBackToSelection
        self.flowSteps = createFlowSteps(for: scannerType)
        self.currentStepKey = initialStep(for: scannerType)
    }

    var currentStep: PointOfSaleBarcodeScannerSetupStep? {
        flowSteps[currentStepKey]
    }

    func nextStep() {
        transition(to: .next)
    }

    func previousStep() {
        transition(to: .back) { [weak self] in
            // If no back transition is defined, go back to selection
            self?.trackSetupBack()
            self?.onBackToSelection()
        }
    }

    func restartFlow() {
        currentStepKey = .setupBarcodeHID
    }

    // MARK: - Generic Transition Methods

    func transition(to transitionType: PointOfSaleBarcodeScannerTransitionType) {
        self.transition(to: transitionType, fallback: nil)
    }

    func transition(to stepKey: PointOfSaleBarcodeScannerStepID) {
        self.currentStepKey = stepKey
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
                title: Localization.nextButtonTitle,
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
              let targetStep = currentStep.transitions[transitionType] else {
            fallback?()
            return
        }

        switch transitionType {
        case .next:
            trackSetupNext()
        case .back:
            trackSetupBack()
        case .retry:
            trackRetry()
        }

        currentStepKey = targetStep
    }

    private func createFlowSteps(for scannerType: PointOfSaleBarcodeScannerType) -> [PointOfSaleBarcodeScannerStepID: PointOfSaleBarcodeScannerSetupStep] {
        switch scannerType {
        case .socketS720:
            return [
                .setupBarcodeHID: createWelcomeStep(title: "Socket S720 Setup")
                // TODO: Add more steps for Socket S720 WOOMOB-698
            ]
        case .starBSH20B:
            return [
                .setupBarcodeHID: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerBarcodeView(
                            title: String(format: Localization.scannerSetUpBarcodeStepTitleFormat, scannerType.name),
                            instruction: Localization.setUpBarcodeHIDStepInstruction,
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
                        .back: .setupBarcodeHID
                    ]
                ),
                .test: testScanStep(barcode: .ean13),
                .testScanTimedOut: testScanTimeOutStep(barcode: .ean13),
                .testScanFailed: testScanFailedStep(),
                .complete: setupCompleteStep(),
                .setupInformation: setupInformationStep()
            ]
        case .tera12002D:
            return [
                .setupBarcodeHID: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerBarcodeView(
                            title: Localization.scannerSetUpBarcodeStepTitleFormat,
                            instruction: Localization.setUpBarcodeHIDStepInstruction,
                            barcode: .tera12002DHIDBarcode)
                    },
                    transitions: [
                        .next: .setupBarcodePair,
                    ]
                ),
                .setupBarcodePair: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerBarcodeView(
                            title: Localization.scannerSetUpBarcodeStepTitleFormat,
                            instruction: Localization.setUpBarcodePairStepInstruction,
                            barcode: .tera12002DPairBarcode)
                    },
                    transitions: [
                        .next: .pairing,
                        .back: .setupBarcodeHID
                    ]
                ),
                .pairing: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerPairingView(scanner: scannerType)
                    },
                    transitions: [
                        .next: .test,
                        .back: .setupBarcodePair
                    ]
                ),
                .test: testScanStep(barcode: .ean13),
                .testScanTimedOut: testScanTimeOutStep(barcode: .ean13),
                .testScanFailed: testScanFailedStep(),
                .complete: setupCompleteStep(),
                .setupInformation: setupInformationStep()
            ]
        case .other:
            return [
                .setupInformation: PointOfSaleBarcodeScannerSetupStep(
                    content: { BarcodeScannerInformation() },
                    transitions: [.next: .setupProducts]
                ),
                .setupProducts: PointOfSaleBarcodeScannerSetupStep(
                    content: { ProductBarcodeSetupInformation() },
                    buttonCustomization: PointOfSaleBarcodeScannerBackOnlyButtonCustomization(),
                    transitions: [.back: .setupInformation]
                )
            ]
        }
    }

    private func initialStep(for scannerType: PointOfSaleBarcodeScannerType) -> PointOfSaleBarcodeScannerStepID {
        switch scannerType {
        case .socketS720, .starBSH20B, .tera12002D:
            return .setupBarcodeHID
        case .other:
            return .setupInformation
        }
    }

    func getCurrentAnalyticsStepValue() -> String? {
        return currentStepKey.analyticsValue
    }

    private func createWelcomeStep(title: String) -> PointOfSaleBarcodeScannerSetupStep {
        PointOfSaleBarcodeScannerSetupStep(
            title: title,
            content: { PointOfSaleBarcodeScannerWelcomeView(title: title) },
            buttonCustomization: PointOfSaleBarcodeScannerWelcomeButtonCustomization()
        )
    }

    // MARK: - Steps

    private func testScanStep(barcode: PointOfSaleBarcodeScannerTestBarcode, timerCompleted: Bool = false) -> PointOfSaleBarcodeScannerSetupStep {
        PointOfSaleBarcodeScannerSetupStep(
            content: {
                PointOfSaleBarcodeScannerTestBarcodeView(
                    scanTester: PointOfSaleBarcodeScannerSetupScanTester(
                        onTestPass: { [weak self] in
                            self?.trackTestScanSuccess()
                            self?.transition(to: .complete)
                        },
                        onTestFailure: { [weak self] barcode in
                            self?.trackTestScanFailed(scanValue: barcode)
                            self?.transition(to: .testScanFailed)
                        },
                        onTestTimeout: { [weak self] in
                            self?.trackTestScanTimedOut()
                            self?.transition(to: .testScanTimedOut)
                        },
                        barcodeDefinition: barcode),
                    timerCompleted: timerCompleted
                )
            },
            buttonCustomization: PointOfSaleBarcodeScannerBackOnlyButtonCustomization(),
            transitions: [
                .back: .pairing
            ]
        )
    }

    private func testScanTimeOutStep(barcode: PointOfSaleBarcodeScannerTestBarcode) -> PointOfSaleBarcodeScannerSetupStep {
        testScanStep(barcode: barcode, timerCompleted: true)
    }

    private func testScanFailedStep() -> PointOfSaleBarcodeScannerSetupStep {
        PointOfSaleBarcodeScannerSetupStep(
            content: {
                PointOfSaleBarcodeScannerErrorView()
            },
            buttonCustomization: PointOfSaleBarcodeScannerErrorButtonCustomization(),
            transitions: [
                .retry: .setupBarcodeHID,
                .back: .test
            ]
        )
    }

    private func setupCompleteStep() -> PointOfSaleBarcodeScannerSetupStep {
        PointOfSaleBarcodeScannerSetupStep(
            content: {
                PointOfSaleBarcodeScannerSetupCompleteView()
            },
            buttonCustomization: PointOfSaleBarcodeScannerOptionalScannerInformationButtonCustomization(),
            transitions: [
                .next: .setupInformation,
            ])
    }

    private func setupInformationStep() -> PointOfSaleBarcodeScannerSetupStep {
        PointOfSaleBarcodeScannerSetupStep(
            content: { ProductBarcodeSetupInformation() },
            buttonCustomization: PointOfSaleBarcodeScannerNoButtonsButtonCustomization()
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

// MARK: - Analytics

@available(iOS 17.0, *)
private extension PointOfSaleBarcodeScannerSetupFlow {
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

    private func trackRetry() {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupRetryTapped(scanner: scannerType))
    }
}

// MARK: - Private Localization Extension
@available(iOS 17.0, *)
private extension PointOfSaleBarcodeScannerSetupFlow {
    enum Localization {
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
        static let scannerSetUpBarcodeStepTitleFormat = "Scanner Setup"
        static let setUpBarcodeHIDStepInstruction = "Scan the Bluetooth HID symbol."
        static let setUpBarcodePairStepInstruction = "Scan the Pair symbol to get the scanner ready for pairing."
    }
}
