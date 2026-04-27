import SwiftUI

// MARK: - Point of Sale Barcode Scanner Setup Flow
@Observable
class PointOfSaleBarcodeScannerSetupFlow {
    private let scannerType: PointOfSaleBarcodeScannerType
    private let onBackToSelection: () -> Void
    fileprivate let onDismiss: () -> Void
    private var flowSteps: [PointOfSaleBarcodeScannerStepID: PointOfSaleBarcodeScannerSetupStep] = [:]
    private(set) var currentStepKey: PointOfSaleBarcodeScannerStepID = .setupBarcodeHID
    private let analytics: POSAnalyticsProviding

    init(scannerType: PointOfSaleBarcodeScannerType,
         analytics: POSAnalyticsProviding,
         onBackToSelection: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        self.scannerType = scannerType
        self.analytics = analytics
        self.onBackToSelection = onBackToSelection
        self.onDismiss = onDismiss
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
        guard let currentStep,
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
                .setupProducts: setupProductsStep()
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
                .setupProducts: setupProductsStep()
            ]
        case .netum1228BC:
            return [
                .setupBarcodeHID: PointOfSaleBarcodeScannerSetupStep(
                    content: {
                        PointOfSaleBarcodeScannerBarcodeView(
                            title: Localization.scannerSetUpBarcodeStepTitleFormat,
                            instruction: Localization.setUpBarcodeHIDStepInstruction,
                            barcode: .netum1228BCHIDBarcode)
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
                            barcode: .netum1228BCPairBarcode)
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
                .setupProducts: setupProductsStep()
            ]
        case .other:
            return [
                .setupInformation: PointOfSaleBarcodeScannerSetupStep(
                    content: { BarcodeScannerInformation() },
                    transitions: [.next: .test]
                ),
                .test: testScanStep(barcode: .ean13, transitions: [.back: .setupInformation]),
                .testScanTimedOut: testScanTimeOutStep(barcode: .ean13, transitions: [.back: .setupInformation]),
                .testScanFailed: testScanFailedStep(),
                .complete: setupCompleteStep(),
                .setupProducts: setupProductsStep()
            ]
        }
    }

    private func initialStep(for scannerType: PointOfSaleBarcodeScannerType) -> PointOfSaleBarcodeScannerStepID {
        switch scannerType {
        case .starBSH20B, .tera12002D, .netum1228BC:
            return .setupBarcodeHID
        case .other:
            return .setupInformation
        }
    }

    func getCurrentAnalyticsStepValue() -> String? {
        return currentStepKey.analyticsValue
    }

    // MARK: - Steps

    private func testScanStep(
        barcode: PointOfSaleBarcodeScannerTestBarcode,
        transitions: [PointOfSaleBarcodeScannerTransitionType: PointOfSaleBarcodeScannerStepID] = [.back: .pairing],
        timerCompleted: Bool = false
    ) -> PointOfSaleBarcodeScannerSetupStep {
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
            transitions: transitions
        )
    }

    private func testScanTimeOutStep(
        barcode: PointOfSaleBarcodeScannerTestBarcode,
        transitions: [PointOfSaleBarcodeScannerTransitionType: PointOfSaleBarcodeScannerStepID] = [.back: .pairing]
    ) -> PointOfSaleBarcodeScannerSetupStep {
        testScanStep(barcode: barcode, transitions: transitions, timerCompleted: true)
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
                .next: .setupProducts
            ])
    }

    private func setupProductsStep() -> PointOfSaleBarcodeScannerSetupStep {
        PointOfSaleBarcodeScannerSetupStep(
            content: { ProductBarcodeSetupInformation() },
            buttonCustomization: PointOfSaleBarcodeScannerProductBarcodeSetupInformationButtonCustomization(),
            transitions: [
                .back: .complete
            ]
        )
    }
}

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
        static let informationButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.productBarcodeInformation.button.title",
            value: "How to set up barcodes on products",
            comment: "Button title for accessing product barcode setup information"
        )
    }
}

struct PointOfSaleBarcodeScannerProductBarcodeSetupInformationButtonCustomization: PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration {
        return PointOfSaleFlowButtonConfiguration(
            primaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: PointOfSaleBarcodeScannerSetupFlow.Localization.doneButtonTitle,
                action: { flow.onDismiss() }
            ),
            secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: PointOfSaleBarcodeScannerSetupFlow.Localization.backButtonTitle,
                action: { flow.transition(to: .back) }
            )
        )
    }
}

// MARK: - Analytics

private extension PointOfSaleBarcodeScannerSetupFlow {
    private func trackTestScanSuccess() {
        analytics.track(event: .PointOfSale.barcodeScannerSetupTestScanSuccess(scanner: scannerType))
    }

    private func trackTestScanFailed(scanValue: String) {
        analytics.track(event: .PointOfSale.barcodeScannerSetupTestScanFailed(scanner: scannerType, scanValue: scanValue))
    }

    private func trackTestScanTimedOut() {
        analytics.track(event: .PointOfSale.barcodeScannerSetupTestScanTimedOut(scanner: scannerType))
    }

    private func trackSetupNext() {
        if let step = getCurrentAnalyticsStepValue() {
            analytics.track(event: .PointOfSale.barcodeScannerSetupNextTapped(scanner: scannerType, step: step))
        }
    }

    private func trackSetupBack() {
        if let step = getCurrentAnalyticsStepValue() {
            analytics.track(event: .PointOfSale.barcodeScannerSetupBackTapped(scanner: scannerType, step: step))
        }
    }

    private func trackRetry() {
        analytics.track(event: .PointOfSale.barcodeScannerSetupRetryTapped(scanner: scannerType))
    }
}

// MARK: - Private Localization Extension
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

        static let doneButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.done.button.title",
            value: "Done",
            comment: "Title for the done button in barcode scanner setup navigation"
        )

        static let scannerSetUpBarcodeStepTitleFormat = NSLocalizedString(
            "pos.barcodeScannerSetup.scanner.setup.title.format",
            value: "Scanner setup",
            comment: "Title format for barcode scanner setup step"
        )
        static let setUpBarcodeHIDStepInstruction = NSLocalizedString(
            "pos.barcodeScannerSetup.hidSetup.instruction",
            value: "Use your barcode scanner to scan the code below to enable Bluetooth HID mode.",
            comment: "Instruction for scanning the Bluetooth HID barcode during scanner setup"
        )
        static let setUpBarcodePairStepInstruction = NSLocalizedString(
            "pos.barcodeScannerSetup.pairSetup.instruction",
            value: "Use your barcode scanner to scan the code below to enter pairing mode.",
            comment: "Instruction for scanning the Pair barcode to prepare scanner for pairing"
        )
    }
}
