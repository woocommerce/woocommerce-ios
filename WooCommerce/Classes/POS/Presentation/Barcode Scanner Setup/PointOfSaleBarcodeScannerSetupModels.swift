import SwiftUI

// MARK: - Data Models
struct PointOfSaleBarcodeScannerSetupFlowOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let scannerType: ScannerType
}

enum ScannerType {
    case socketS720
    case starBSH20B
    case tbcScanner
    case other
}

// MARK: - Flow State
enum PointOfSaleBarcodeScannerSetupFlowState {
    case scannerSelection
    case setupFlow(ScannerType)
}

// MARK: - Button Configuration
struct ButtonConfiguration {
    let shouldShowBackButton: Bool
    let shouldShowNextButton: Bool
    let nextButtonTitle: String
    let isNextButtonEnabled: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    static func noButtons() -> ButtonConfiguration {
        .init(
            shouldShowBackButton: false,
            shouldShowNextButton: false,
            nextButtonTitle: "",
            isNextButtonEnabled: false,
            onBack: {},
            onNext: {}
        )
    }

    static func doneOnly(onDone: @escaping () -> Void) -> ButtonConfiguration {
        .init(
            shouldShowBackButton: false,
            shouldShowNextButton: true,
            nextButtonTitle: Localization.doneButtonTitle,
            isNextButtonEnabled: true,
            onBack: {},
            onNext: onDone
        )
    }

    static func closeAndRetry(onClose: @escaping () -> Void, onRetry: @escaping () -> Void) -> ButtonConfiguration {
        .init(
            shouldShowBackButton: true,
            shouldShowNextButton: true,
            nextButtonTitle: Localization.retryButtonTitle,
            isNextButtonEnabled: true,
            onBack: onClose,
            onNext: onRetry
        )
    }

    static func disabledNext(onBack: @escaping () -> Void, onNext: @escaping () -> Void) -> ButtonConfiguration {
        .init(
            shouldShowBackButton: true,
            shouldShowNextButton: true,
            nextButtonTitle: Localization.nextButtonTitle,
            isNextButtonEnabled: false,
            onBack: onBack,
            onNext: onNext
        )
    }
}

// MARK: - Private Localization Extension
private extension ButtonConfiguration {
    enum Localization {
        static let doneButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.done.button.title",
            value: "Done",
            comment: "Title for the done button in barcode scanner setup navigation"
        )
        static let retryButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.retry.button.title",
            value: "Retry",
            comment: "Title for the retry button in barcode scanner setup navigation"
        )
        static let nextButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.next.button.title",
            value: "Next",
            comment: "Title for the next button in barcode scanner setup navigation"
        )
    }
}

// MARK: - Step Customization Protocol
@available(iOS 17.0, *)
protocol PointOfSaleBarcodeScannerStepCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> ButtonConfiguration
}

// MARK: - Setup Step
@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetupStep {
    let title: String
    let content: any View
    let customization: PointOfSaleBarcodeScannerStepCustomization?

    init(
        title: String,
        @ViewBuilder content: () -> any View,
        customization: PointOfSaleBarcodeScannerStepCustomization? = nil
    ) {
        self.title = title
        self.content = content()
        self.customization = customization
    }
}
