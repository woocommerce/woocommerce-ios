import Foundation
import Yosemite

/// View model for `LoginJetpackSetupView`.
///
final class LoginJetpackSetupViewModel: ObservableObject {
    let siteURL: String
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    let connectionOnly: Bool
    private let stores: StoresManager
    private let storeNavigationHandler: () -> Void

    let setupSteps: [JetpackInstallStep]
    let title: String

    @Published private(set) var currentSetupStep: JetpackInstallStep?
    @Published private(set) var currentConnectionStep: ConnectionStep = .pending
    @Published private(set) var jetpackConnectionURL: URL?
    @Published var shouldPresentWebView = false

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

    init(siteURL: String, connectionOnly: Bool, stores: StoresManager = ServiceLocator.stores, onStoreNavigation: @escaping () -> Void = {}) {
        self.siteURL = siteURL
        self.connectionOnly = connectionOnly
        self.stores = stores
        let setupSteps = connectionOnly ? [.connection, .done] : JetpackInstallStep.allCases
        self.setupSteps = setupSteps
        self.title = connectionOnly ? Localization.connectingJetpack : Localization.installingJetpack
        self.storeNavigationHandler = onStoreNavigation
    }

    func isSetupStepInProgress(_ step: JetpackInstallStep) -> Bool {
        guard let currentStep = currentSetupStep else {
            return false
        }
        return step == currentStep && step != .done
    }

    func isSetupStepPending(_ step: JetpackInstallStep) -> Bool {
        guard let currentStep = currentSetupStep else {
            return false
        }
        return step > currentStep
    }

    func startSetup() {
        retrieveJetpackPluginDetails()
    }

    func authorizeJetpackConnection() {
        checkJetpackConnection()
    }

    func navigateToStore() {
        storeNavigationHandler()
    }
}

// MARK: Private helpers
//
private extension LoginJetpackSetupViewModel {
    func retrieveJetpackPluginDetails() {
        let action = JetpackConnectionAction.retrieveJetpackPluginDetails { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let plugin):
                if plugin.status == .inactive {
                    self.activateJetpack()
                } else {
                    self.fetchJetpackConnectionURL()
                }
            case .failure(let error):
                // TODO: handle error
                print(error)
                self.installJetpack()
            }
        }
        stores.dispatch(action)
    }

    func installJetpack() {
        currentSetupStep = .installation
        let action = JetpackConnectionAction.installJetpackPlugin { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.activateJetpack()
            case .failure(let error):
                // TODO: handle error
                print(error)
            }
        }
        stores.dispatch(action)
    }

    func activateJetpack() {
        currentSetupStep = .activation
        let action = JetpackConnectionAction.activateJetpackPlugin { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.fetchJetpackConnectionURL()
            case .failure(let error):
                // TODO: handle error
                print(error)
            }
        }
        stores.dispatch(action)
    }

    func fetchJetpackConnectionURL() {
        currentSetupStep = .connection
        let action = JetpackConnectionAction.fetchJetpackConnectionURL { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let url):
                self.jetpackConnectionURL = url
                self.shouldPresentWebView = true
            case .failure(let error):
                // TODO: handle error
                print(error)
            }
        }
        stores.dispatch(action)
    }

    func checkJetpackConnection() {
        currentConnectionStep = .inProgress
        let action = JetpackConnectionAction.fetchJetpackUser { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let user):
                guard user.wpcomUser?.email != nil else {
                    DDLogWarn("⚠️ Cannot find connected WPcom user")
                    return // TODO: add tracks and handle error
                }

                self.currentConnectionStep = .authorized
                self.currentSetupStep = .done
            case .failure(let error):
                // TODO: handle error
                print(error)
            }
        }
        stores.dispatch(action)
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
