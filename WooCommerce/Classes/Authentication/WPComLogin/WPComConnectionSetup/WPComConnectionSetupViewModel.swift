import Foundation
import Combine
import SwiftUI

class WPComConnectionSetupViewModel: ObservableObject {

    @Published private(set) var steps: [WPComConnectionSetupStep] = []

    @Published private(set) var primaryButtonTitle: String = Localization.goToMyStore
    @Published private(set) var isPrimaryButtonEnabled: Bool = false

    @Published private(set) var secondaryButtonTitle: String = Localization.tryAgain
    @Published private(set) var isShowingSecondaryButton: Bool = false

    let subtitleAttributedString: AttributedString

    private let storeName: String

    init(storeName: String) {
        self.storeName = storeName
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
    }

    func onAppear() {
        setInitialState()
    }

    func primaryButtonTapped() {

    }

    func secondaryButtonTapped() {

    }

    private func setInitialState() {
        steps = [
            WPComConnectionSetupStep(title: Localization.connectStoreStep, status: .running),
            WPComConnectionSetupStep(title: Localization.checkPluginStep, status: .notStarted),
            WPComConnectionSetupStep(title: Localization.enablePushNotificationsStep, status: .notStarted)
        ]

        primaryButtonTitle = Localization.goToMyStore
        isPrimaryButtonEnabled = false
        isShowingSecondaryButton = false
    }
}

extension WPComConnectionSetupViewModel {
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
