import Foundation
import Yosemite

/// View model for `LoginJetpackSetupView`.
///
final class LoginJetpackSetupViewModel: ObservableObject {
    let siteURL: String
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    let connectionOnly: Bool
    private let stores: StoresManager

    let setupSteps: [JetpackInstallStep]
    let title: String

    @Published private(set) var currentSetupStep: JetpackInstallStep
    @Published private(set) var currentConnectionStep: ConnectionStep = .pending

    /// Attributed string for the description text
    lazy private(set) var descriptionAttributedString: NSAttributedString = {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold
        let siteName = siteURL.trimHTTPScheme()

        let attributedString = NSMutableAttributedString(
            string: String(format: Localization.description, siteName),
            attributes: [.font: font,
                         .foregroundColor: UIColor.text.withAlphaComponent(0.8)
                        ]
        )
        let boldSiteAddress = NSAttributedString(string: siteName, attributes: [.font: boldFont, .foregroundColor: UIColor.text])
        attributedString.replaceFirstOccurrence(of: siteName, with: boldSiteAddress)
        return attributedString
    }()

    init(siteURL: String, connectionOnly: Bool, stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.connectionOnly = connectionOnly
        self.stores = stores
        let setupSteps = connectionOnly ? [.connection, .done] : JetpackInstallStep.allCases
        self.setupSteps = setupSteps
        self.currentSetupStep = setupSteps[0]
        self.title = connectionOnly ? Localization.connectingJetpack : Localization.installingJetpack
    }

    func isSetupStepInProgress(_ step: JetpackInstallStep) -> Bool {
        step == currentSetupStep && step != .done
    }

    func isSetupStepPending(_ step: JetpackInstallStep) -> Bool {
        step > currentSetupStep
    }
}

// MARK: Subtypes
//
extension LoginJetpackSetupViewModel {
    enum ConnectionStep {
        case pending
        case inProgress
        case authorized

        var title: String {
            switch self {
            case .pending:
                return LoginJetpackSetupViewModel.Localization.approvalRequired
            case .inProgress:
                return LoginJetpackSetupViewModel.Localization.validating
            case .authorized:
                return LoginJetpackSetupViewModel.Localization.connectionApproved
            }
        }

        var imageName: String? {
            switch self {
            case .pending:
                return "info.circle.fill"
            case .inProgress, .authorized:
                return nil
            }
        }

        var tintColor: UIColor {
            switch self {
            case .pending:
                return .wooOrange
            case .inProgress:
                return .secondaryLabel
            case .authorized:
                return .withColorStudio(.green, shade: .shade50)
            }
        }
    }

    enum Localization {
        static let installingJetpack = NSLocalizedString(
            "Installing Jetpack",
            comment: "Title for the Jetpack setup screen when installation is required"
        )
        static let connectingJetpack = NSLocalizedString(
            "Connecting Jetpack",
            comment: "Title for the Jetpack setup screen when connection is required"
        )
        static let description = NSLocalizedString(
            "Please wait while we connect your store %1$@ with Jetpack.",
            comment: "Message on the Jetpack setup screen. The %1$@ is the site address."
        )
        static let approvalRequired = NSLocalizedString(
            "Approval required",
            comment: "Message to be displayed when a Jetpack connection is pending approval"
        )
        static let validating = NSLocalizedString(
            "Validating",
            comment: "Message to be displayed when a Jetpack connection is being authorized"
        )
        static let connectionApproved = NSLocalizedString(
            "Connection approved",
            comment: "Message to be displayed when a Jetpack connection has been authorized"
        )
    }
}
