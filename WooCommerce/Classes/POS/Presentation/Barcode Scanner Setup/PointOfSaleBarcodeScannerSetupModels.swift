import SwiftUI

// MARK: - Data Models
struct PointOfSaleBarcodeScannerSetupFlowOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let scannerType: PointOfSaleBarcodeScannerType
}

enum PointOfSaleBarcodeScannerType {
    case socketS720
    case starBSH20B
    case tbcScanner
    case other
}

// MARK: - Flow State
enum PointOfSaleBarcodeScannerSetupFlowState {
    case scannerSelection
    case setupFlow(PointOfSaleBarcodeScannerType)
}

// MARK: - Button Configuration
struct PointOfSaleFlowButtonConfiguration {
    let shouldShowBackButton: Bool
    let shouldShowNextButton: Bool
    let nextButtonTitle: String
    let isNextButtonEnabled: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    static func noButtons() -> PointOfSaleFlowButtonConfiguration {
        .init(
            shouldShowBackButton: false,
            shouldShowNextButton: false,
            nextButtonTitle: "",
            isNextButtonEnabled: false,
            onBack: {},
            onNext: {}
        )
    }

    static func doneOnly(onDone: @escaping () -> Void) -> PointOfSaleFlowButtonConfiguration {
        .init(
            shouldShowBackButton: false,
            shouldShowNextButton: true,
            nextButtonTitle: Localization.doneButtonTitle,
            isNextButtonEnabled: true,
            onBack: {},
            onNext: onDone
        )
    }

    static func closeAndRetry(onClose: @escaping () -> Void,
                              onRetry: @escaping () -> Void) -> PointOfSaleFlowButtonConfiguration {
        .init(
            shouldShowBackButton: true,
            shouldShowNextButton: true,
            nextButtonTitle: Localization.retryButtonTitle,
            isNextButtonEnabled: true,
            onBack: onClose,
            onNext: onRetry
        )
    }

    static func disabledNext(onBack: @escaping () -> Void,
                             onNext: @escaping () -> Void) -> PointOfSaleFlowButtonConfiguration {
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
private extension PointOfSaleFlowButtonConfiguration {
    enum Localization {
        static let doneButtonTitle = NSLocalizedString(
            "pos.flow.done.button.title",
            value: "Done",
            comment: "Title for the done button in a step by step flow view in POS"
        )
        static let retryButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.retry.button.title",
            value: "Retry",
            comment: "Title for the retry button in a step by step flow view in POS"
        )
        static let nextButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.next.button.title",
            value: "Next",
            comment: "Title for the next button in a step by step flow view in POS"
        )
    }
}

// MARK: - Step Customization Protocol
@available(iOS 17.0, *)
protocol PointOfSaleBarcodeScannerStepCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration
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
