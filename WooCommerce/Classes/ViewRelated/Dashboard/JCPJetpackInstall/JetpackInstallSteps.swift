import Foundation

/// Enum respresenting steps for installing Jetpack for a site.
/// Used for displaying steps on `JCPJetpackInstallStepsView` and `JetpackSetupView`.
///
enum JetpackInstallStep: Int, CaseIterable {
    case installation
    case activation
    case connection
    case done
}

extension JetpackInstallStep: Identifiable {
    var id: Int {
        rawValue
    }
}

extension JetpackInstallStep: Comparable {
    static func < (lhs: JetpackInstallStep, rhs: JetpackInstallStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension JetpackInstallStep {

    /// Display text of the step
    ///
    var title: String {
        switch self {
        case .installation:
            return Localization.installationStep
        case .activation:
            return Localization.activationStep
        case .connection:
            return Localization.connectionStep
        case .done:
            return Localization.finalStep
        }
    }

    /// Error title to display when Jetpack setup fails on the step
    ///
    var errorTitle: String? {
        switch self {
        case .installation:
            return Localization.installErrorTitle
        case .activation:
            return Localization.activationErrorTitle
        case .connection:
            return Localization.connectionErrorTitle
        case .done:
            return nil
        }
    }

    /// Error message to display when Jetpack install fails on the step
    ///
    var errorMessage: String? {
        switch self {
        case .installation:
            return Localization.installErrorMessage
        case .activation:
            return Localization.activationErrorMessage
        case .connection:
            return Localization.connectionErrorMessage
        case .done:
            return nil
        }
    }

    /// Title of the CTA to display when Jetpack install fails on the step
    ///
    var errorActionTitle: String? {
        switch self {
        case .installation:
            return Localization.wpAdminInstallAction
        case .activation:
            return Localization.wpAdminActivateAction
        case .connection:
            return Localization.checkConnectionAction
        case .done:
            return nil
        }
    }

    var tryAgainButtonTitle: String? {
        switch self {
        case .installation:
            return Localization.tryInstallingAgain
        case .activation:
            return Localization.tryActivatingAgain
        case .connection:
            return Localization.tryAuthorizingAgain
        case .done:
            return nil
        }
    }

    /// Description dictionary for Analytics
    ///
    var analyticsDescription: [String: String] {
        ["jetpack_install_step": analyticsValue]
    }

    var analyticsValue: String {
        switch self {
        case .installation:
            return "installation"
        case .activation:
            return "activation"
        case .connection:
            return "connection"
        case .done:
            return "all_done"
        }
    }

    private enum Localization {
        static let installationStep = NSLocalizedString("Installing Jetpack", comment: "Name of installing Jetpack plugin step")
        static let activationStep = NSLocalizedString("Activating", comment: "Name of the activation Jetpack plugin step")
        static let connectionStep = NSLocalizedString("Connecting your store", comment: "Name of the step to connect the store to Jetpack")
        static let finalStep = NSLocalizedString("All done", comment: "Name of final step in Install Jetpack flow.")
        static let installErrorTitle = NSLocalizedString("Error installing Jetpack",
                                                         comment: "Error title when Jetpack install fails")
        static let activationErrorTitle = NSLocalizedString("Error activating Jetpack",
                                                            comment: "Error title when Jetpack activation fails")
        static let connectionErrorTitle = NSLocalizedString("Error authorizing connection to Jetpack",
                                                            comment: "Error title when Jetpack connection fails")
        static let installErrorMessage = NSLocalizedString("Please try again. Alternatively, you can install Jetpack through your WP-Admin.",
                                                    comment: "Error message when Jetpack install fails")
        static let activationErrorMessage = NSLocalizedString("Please try again. Alternatively, you can activate Jetpack through your WP-Admin.",
                                                    comment: "Error message when Jetpack activation fails")
        static let connectionErrorMessage = NSLocalizedString("Please try again or contact us for support.",
                                                              comment: "Error message when Jetpack connection fails")
        static let wpAdminInstallAction = NSLocalizedString("Install Jetpack in WP-Admin",
                                                            comment: "Action button to install Jetpack on WP-Admin instead of on app")
        static let wpAdminActivateAction = NSLocalizedString("Activate Jetpack in WP-Admin",
                                                             comment: "Action button to activate Jetpack on WP-Admin instead of on app")
        static let checkConnectionAction = NSLocalizedString("Retry Connection", comment: "Action button to check site's connection again.")
        static let tryInstallingAgain = NSLocalizedString("Try Installing Again", comment: "Action button to retry Jetpack installation.")
        static let tryActivatingAgain = NSLocalizedString("Try Activating Again", comment: "Action button to retry Jetpack activation.")
        static let tryAuthorizingAgain = NSLocalizedString("Try Authorizing Again", comment: "Action button to retry Jetpack connection.")
    }
}
