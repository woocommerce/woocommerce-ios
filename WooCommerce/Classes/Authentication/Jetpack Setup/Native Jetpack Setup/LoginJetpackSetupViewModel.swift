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

    @Published private(set) var currentStep: JetpackInstallStep

    init(siteURL: String, connectionOnly: Bool, stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.connectionOnly = connectionOnly
        self.stores = stores
        let setupSteps = connectionOnly ? [.connection, .done] : JetpackInstallStep.allCases
        self.setupSteps = setupSteps
        self.currentStep = setupSteps[0]
    }
}
