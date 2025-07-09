import SwiftUI

struct PointOfSaleFlowButtonsView: View {
    let configuration: PointOfSaleFlowButtonConfiguration

    var body: some View {
        HStack(spacing: POSSpacing.medium) {
            if configuration.shouldShowBackButton {
                Button(configuration.backButtonTitle) {
                    configuration.onBack()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
            if configuration.shouldShowNextButton {
                Button(configuration.nextButtonTitle) {
                    configuration.onNext()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(!configuration.isNextButtonEnabled)
            }
        }
    }
}

// MARK: - Button Configuration
struct PointOfSaleFlowButtonConfiguration {
    let shouldShowBackButton: Bool
    let shouldShowNextButton: Bool
    let backButtonTitle: String
    let nextButtonTitle: String
    let isNextButtonEnabled: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    static func noButtons() -> PointOfSaleFlowButtonConfiguration {
        .init(
            shouldShowBackButton: false,
            shouldShowNextButton: false,
            backButtonTitle: "",
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
            backButtonTitle: "",
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
            backButtonTitle: Localization.closeButtonTitle,
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
            backButtonTitle: Localization.backButtonTitle,
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
            "pos.flow.retry.button.title",
            value: "Retry",
            comment: "Title for the retry button in a step by step flow view in POS"
        )
        static let nextButtonTitle = NSLocalizedString(
            "pos.flow.next.button.title",
            value: "Next",
            comment: "Title for the next button in a step by step flow view in POS"
        )
        static let backButtonTitle = NSLocalizedString(
            "pos.flow.back.button.title",
            value: "Back",
            comment: "Title for the back button in a step by step flow view in POS"
        )
        static let closeButtonTitle = NSLocalizedString(
            "pos.flow.close.button.title",
            value: "Close",
            comment: "Title for the back button in a step by step flow view in POS"
        )
    }
}
