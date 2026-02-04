import Foundation
import Combine
import SwiftUI

@MainActor
final class WPComConnectionSetupViewModel: ObservableObject {
    private enum SetupStatus: Equatable {
        case inProgress
        case completed
        case failed(step: SetupStep, error: CheckPluginError?)
    }

    @Published private(set) var steps: [WPComConnectionSetupStep] = []
    @Published private var setupStatus: SetupStatus = .inProgress

    let subtitleAttributedString: AttributedString

    var primaryButtonTitle: String {
        switch setupStatus {
        case .inProgress, .completed:
            return Localization.goToMyStore
        case .failed(let step, let error):
            switch step {
            case .connect, .enablePush:
                return Localization.tryAgain
            case .checkPlugin:
                if case .outdated = error {
                    return Localization.updatePlugin
                }
                return Localization.tryAgain
            }
        }
    }

    var isPrimaryButtonEnabled: Bool {
        setupStatus != .inProgress
    }

    var isShowingSecondaryButton: Bool {
        if case .failed(step: .checkPlugin, error: .outdated) = setupStatus {
            return true
        }
        return false
    }

    var secondaryButtonTitle: String {
        Localization.tryAgain
    }

    var isShowingDoneButton: Bool {
        setupStatus == .completed
    }

    private let storeName: String
    private let handler: WPComConnectionSetupHandlerProtocol
    private let onDismiss: () -> Void
    private let onGoToStore: () -> Void
    private let onUpdatePlugin: () -> Void

    init(storeName: String,
         handler: WPComConnectionSetupHandlerProtocol,
         onDismiss: @escaping () -> Void,
         onGoToStore: @escaping () -> Void,
         onUpdatePlugin: @escaping () -> Void) {
        self.storeName = storeName
        self.handler = handler
        self.onDismiss = onDismiss
        self.onGoToStore = onGoToStore
        self.onUpdatePlugin = onUpdatePlugin

        self.subtitleAttributedString = {
            let content = String.localizedStringWithFormat(Localization.subtitle, storeName)
            var attributedText = AttributedString(content)
            attributedText.font = .body
            attributedText.foregroundColor = Color(.text)

            if let range = attributedText.range(of: storeName) {
                attributedText[range].font = .body.bold()
            }
            return attributedText
        }()

        self.handler.delegate = self
        setupInitialSteps()
    }

    func onAppear() {
        handler.start()
    }

    func primaryButtonTapped() {
        switch setupStatus {
        case .completed:
            onGoToStore()
        case .failed(let step, let error):
            switch step {
            case .connect, .enablePush:
                retrySetup()
            case .checkPlugin:
                if case .outdated = error {
                    onUpdatePlugin()
                } else {
                    retrySetup()
                }
            }
        case .inProgress:
            break
        }
    }

    func secondaryButtonTapped() {
        retrySetup()
    }

    func cancelTapped() {
        handler.cancel()
        onDismiss()
    }

    func doneTapped() {
        onDismiss()
    }

    private func retrySetup() {
        setupStatus = .inProgress
        handler.retry()
    }

    private func setupInitialSteps() {
        steps = [
            WPComConnectionSetupStep(title: Localization.connectStoreStep, status: .notStarted),
            WPComConnectionSetupStep(title: Localization.checkPluginStep, status: .notStarted),
            WPComConnectionSetupStep(title: Localization.enablePushNotificationsStep, status: .notStarted)
        ]
    }

    private func updateStep(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        assert(step.rawValue < steps.count, "SetupStep out of sync with steps array")
        guard step.rawValue < steps.count else { return }
        steps[step.rawValue] = WPComConnectionSetupStep(
            title: steps[step.rawValue].title,
            status: status
        )
    }
}

extension WPComConnectionSetupViewModel: WPComConnectionSetupHandlerDelegate {
    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupHandler.StepStatus) {
        let uiStatus: WPComConnectionSetupStep.Status
        switch status {
        case .running:
            uiStatus = .running
        case .success:
            uiStatus = .success
        case .failure(let error):
            let message = localizedErrorMessage(for: error, step: step)
            uiStatus = .failure(reason: message)

            let checkPluginError = error as? CheckPluginError
            setupStatus = .failed(step: step, error: checkPluginError)
        }
        updateStep(step, status: uiStatus)
    }

    func setupDidComplete() {
        setupStatus = .completed
    }

    private func localizedErrorMessage(for error: Error, step: SetupStep) -> String {
        switch step {
        case .checkPlugin:
            if case .outdated(let version) = error as? CheckPluginError {
                return String.localizedStringWithFormat(Localization.pluginOutdatedFormat, version)
            }
            return Localization.connectionError
        case .connect, .enablePush:
            return Localization.connectionError
        }
    }
}

private extension WPComConnectionSetupViewModel {
    enum Localization {
        static let subtitle = NSLocalizedString(
            "wpComConnectionSetupViewModel.subtitle",
            value: "Please wait while we finalize connecting your store %@ to your WordPress.com account.",
            comment: "Subtitle for the WPCom connection setup screen. %@ is the store name."
        )

        static let goToMyStore = NSLocalizedString(
            "wpComConnectionSetupViewModel.goToMyStore",
            value: "Go to My Store",
            comment: "Button title to navigate to the store after successful WPCom connection setup."
        )

        static let updatePlugin = NSLocalizedString(
            "wpComConnectionSetupViewModel.updatePlugin",
            value: "Update plugin",
            comment: "Button title to update the plugin when WPCom connection setup fails due to outdated plugin."
        )

        static let tryAgain = NSLocalizedString(
            "wpComConnectionSetupViewModel.tryAgain",
            value: "Try again",
            comment: "Button title to retry the WPCom connection setup after a failure."
        )

        static let connectStoreStep = NSLocalizedString(
            "wpComConnectionSetupViewModel.connectStoreStep",
            value: "Connect store to WordPress.com",
            comment: "Step title for connecting the store to WordPress.com during WPCom connection setup."
        )

        static let checkPluginStep = NSLocalizedString(
            "wpComConnectionSetupViewModel.checkPluginStep",
            value: "Check plugin compatibility",
            comment: "Step title for checking plugin compatibility during WPCom connection setup."
        )

        static let enablePushNotificationsStep = NSLocalizedString(
            "wpComConnectionSetupViewModel.enablePushNotificationsStep",
            value: "Enable push notifications",
            comment: "Step title for enabling push notifications during WPCom connection setup."
        )

        static let connectionError = NSLocalizedString(
            "wpComConnectionSetupHandler.connectionError",
            value: "There was an error completing your request. Please try again or contact support.",
            comment: "Generic error message for WPCom connection setup failures"
        )

        static let pluginOutdatedFormat = NSLocalizedString(
            "wpComConnectionSetupHandler.pluginOutdated",
            value: "Your WooCommerce plugin version %@ needs updating to connect your store.",
            comment: "Error message when WooCommerce plugin is outdated. %@ is the current version."
        )
    }
}
