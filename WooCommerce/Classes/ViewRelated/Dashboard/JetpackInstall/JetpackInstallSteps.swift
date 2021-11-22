import Foundation

/// Enum respresenting steps for installing Jetpack for a site.
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

    private enum Localization {
        static let installationStep = NSLocalizedString("Installing Jetpack", comment: "Name of installing Jetpack plugin step")
        static let activationStep = NSLocalizedString("Activating", comment: "Name of the activation Jetpack plugin step")
        static let connectionStep = NSLocalizedString("Connecting your store", comment: "Name of the step to connect the store to Jetpack")
        static let finalStep = NSLocalizedString("All done", comment: "Name of final step in Install Jetpack flow.")
    }
}
