import Foundation
import Combine
import SwiftUI

@MainActor
final class WPComConnectionSetupViewModel: ObservableObject {

    struct WebViewPresentation: Equatable {
        let url: URL
        let siteURL: String
    }

    enum CheckPluginError: Equatable {
        case outdated
        case other
    }

    private enum SetupState: Equatable {
        case inProgress
        case completed
        case failed(step: SetupStep, checkPluginError: CheckPluginError? = nil)
    }

    @Published private(set) var steps: [WPComConnectionSetupStep] = []
    @Published private var setupState: SetupState = .inProgress

    let subtitleAttributedString: AttributedString

    var primaryButtonTitle: String {
        switch setupState {
        case .inProgress, .completed:
            return Localization.goToMyStore
        case .failed(let step, let checkPluginError):
            switch step {
            case .connect, .enablePush:
                return Localization.tryAgain
            case .checkPlugin:
                return checkPluginError == .outdated ? Localization.updatePlugin : Localization.tryAgain
            }
        }
    }

    var isPrimaryButtonEnabled: Bool {
        setupState != .inProgress
    }

    var isShowingSecondaryButton: Bool {
        if case .failed(step: .checkPlugin, checkPluginError: .outdated) = setupState {
            return true
        }
        return false
    }

    var secondaryButtonTitle: String {
        Localization.tryAgain
    }

    var isShowingDoneButton: Bool {
        setupState == .completed
    }

    private let storeName: String
    private let handler: WPComConnectionSetupHandlerProtocol
    private let onDismiss: () -> Void
    private let onGoToStore: () -> Void
    private let onUpdatePlugin: () -> Void
    private var shouldAutoOpenUpdatePlugin = false

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
        if shouldAutoOpenUpdatePlugin {
            shouldAutoOpenUpdatePlugin = false
            onUpdatePlugin()
            return
        }
        guard setupState == .inProgress else { return }
        handler.start()
    }

    func setPluginOutdatedState(version: String) {
        stepDidUpdate(.checkPlugin, status: .failure(error: .outdatedPlugin(version: version)))
        shouldAutoOpenUpdatePlugin = true
    }

    func primaryButtonTapped() {
        switch setupState {
        case .completed:
            onGoToStore()
        case .failed(let step, let checkPluginError):
            switch step {
            case .connect, .enablePush:
                retrySetup()
            case .checkPlugin:
                if checkPluginError == .outdated {
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
        setupState = .inProgress
        updateStep(.enablePush, status: .notStarted)
        handler.retry()
    }

    private func setupInitialSteps() {
        steps = [
            WPComConnectionSetupStep(title: Localization.checkPluginStep, status: .notStarted),
            WPComConnectionSetupStep(title: Localization.connectStoreStep, status: .notStarted),
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
    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        updateStep(step, status: status)

        if case .failure(let error) = status {
            let checkPluginError: CheckPluginError? = step == .checkPlugin ? checkPluginError(from: error) : nil
            setupState = .failed(step: step, checkPluginError: checkPluginError)
        }
    }

    private func checkPluginError(from error: WPComConnectionSetupStep.ErrorType) -> CheckPluginError {
        switch error {
        case .outdatedPlugin:
            return .outdated
        case .generic:
            return .other
        }
    }

    func setupDidComplete() {
        setupState = .completed
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
    }
}
