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

    @Published private(set) var currentSetupStep: JetpackInstallStep
    @Published private(set) var currentConnectionStep: ConnectionStep = .pending

    init(siteURL: String, connectionOnly: Bool, stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.connectionOnly = connectionOnly
        self.stores = stores
        let setupSteps = connectionOnly ? [.connection, .done] : JetpackInstallStep.allCases
        self.setupSteps = setupSteps
        self.currentSetupStep = setupSteps[0]
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
