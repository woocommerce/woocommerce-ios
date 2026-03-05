import Foundation
import Combine
import SwiftUI
import protocol WooFoundation.Analytics

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
    private var stepIndexMap: [SetupStep: Int] = [:]
    @Published private var setupState: SetupState = .inProgress
    @Published var isShowingGetHelp = false

    static let supportSourceTag = "origin:woo-push-notifications-setup"

    let title: String
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

    private let storeName: String
    private let handler: WPComConnectionSetupHandlerProtocol
    private let analytics: Analytics
    private let onDismiss: () -> Void
    private let onGoToStore: () -> Void
    private let onUpdatePlugin: (@escaping () -> Void) -> Void
    private var shouldAutoOpenUpdatePlugin = false

    init(storeName: String,
         siteAlreadyConnected: Bool = false,
         handler: WPComConnectionSetupHandlerProtocol,
         analytics: Analytics = ServiceLocator.analytics,
         onDismiss: @escaping () -> Void,
         onGoToStore: @escaping () -> Void,
         onUpdatePlugin: @escaping (@escaping () -> Void) -> Void) {
        self.storeName = storeName
        self.handler = handler
        self.analytics = analytics
        self.onDismiss = onDismiss
        self.onGoToStore = onGoToStore
        self.onUpdatePlugin = onUpdatePlugin

        self.title = siteAlreadyConnected ? Localization.titleSetUpPushNotifications : Localization.titleConnectToWordPressCom

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
        setupInitialSteps(siteAlreadyConnected: siteAlreadyConnected)
    }

    func onAppear() {
        if shouldAutoOpenUpdatePlugin {
            shouldAutoOpenUpdatePlugin = false
            onUpdatePlugin { [weak self] in
                self?.retrySetup()
            }
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
            analytics.track(event: .WPComPushNotificationsSetup.flowButtonTap(.goToMyStore))
            onGoToStore()
        case .failed(let step, let checkPluginError):
            switch step {
            case .connect, .enablePush:
                analytics.track(event: .WPComPushNotificationsSetup.flowButtonTap(.tryAgain))
                retrySetup()
            case .checkPlugin:
                if checkPluginError == .outdated {
                    analytics.track(event: .WPComPushNotificationsSetup.flowButtonTap(.updatePlugin))
                    onUpdatePlugin { [weak self] in
                        self?.retrySetup()
                    }
                } else {
                    analytics.track(event: .WPComPushNotificationsSetup.flowButtonTap(.tryAgain))
                    retrySetup()
                }
            }
        case .inProgress:
            break
        }
    }

    func secondaryButtonTapped() {
        analytics.track(event: .WPComPushNotificationsSetup.flowButtonTap(.tryAgain))
        retrySetup()
    }

    func cancelTapped() {
        analytics.track(.pushNotificationsSetupFlowClose)
        onDismiss()
    }

    func getHelpTapped() {
        isShowingGetHelp = true
    }

    private func retrySetup() {
        setupState = .inProgress
        updateStep(.enablePush, status: .notStarted)
        handler.retry()
    }

    private func setupInitialSteps(siteAlreadyConnected: Bool) {
        var stepsAndTitles: [(SetupStep, String)] = [
            (.checkPlugin, Localization.checkPluginStep)
        ]
        if !siteAlreadyConnected {
            stepsAndTitles.append((.connect, Localization.connectStoreStep))
        }
        stepsAndTitles.append((.enablePush, Localization.enablePushNotificationsStep))

        steps = stepsAndTitles.map { WPComConnectionSetupStep(title: $0.1, status: .notStarted) }
        stepIndexMap = Dictionary(uniqueKeysWithValues: stepsAndTitles.enumerated().map { ($0.element.0, $0.offset) })
    }

    private func updateStep(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        guard let index = stepIndexMap[step] else { return }
        steps[index] = WPComConnectionSetupStep(
            title: steps[index].title,
            status: status
        )
    }
}

extension WPComConnectionSetupViewModel: WPComConnectionSetupHandlerDelegate {
    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        updateStep(step, status: status)

        switch status {
        case .success:
            analytics.track(.pushNotificationsSetupFlowSuccess, withProperties: ["step": step.analyticsKey])
        case .failure(let error):
            analytics.track(.pushNotificationsSetupFlowError, properties: ["step": step.analyticsKey], error: error)
            let checkPluginError: CheckPluginError? = step == .checkPlugin ? checkPluginError(from: error) : nil
            setupState = .failed(step: step, checkPluginError: checkPluginError)
        case .notStarted, .running:
            break
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
        static let titleConnectToWordPressCom = NSLocalizedString(
            "wpComConnectionSetupViewModel.titleConnectToWordPressCom",
            value: "Connect to WordPress.com",
            comment: "Title for the WPCom connection setup screen when the site is not yet connected."
        )
        static let titleSetUpPushNotifications = NSLocalizedString(
            "wpComConnectionSetupViewModel.titleSetUpPushNotifications",
            value: "Set up push notifications",
            comment: "Title for the WPCom connection setup screen when the site is already connected to WordPress.com."
        )
        static let subtitle = NSLocalizedString(
            "wpComConnectionSetupViewModel.message",
            value: "Please wait while we finalize connecting your store %1$@ to WordPress.com.",
            comment: "Subtitle for the WPCom connection setup screen. %1$@ is the store name."
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
