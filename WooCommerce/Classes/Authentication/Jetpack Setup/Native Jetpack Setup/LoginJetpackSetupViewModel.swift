import Foundation
import Yosemite

/// View model for `LoginJetpackSetupView`.
///
final class LoginJetpackSetupViewModel: ObservableObject {
    let siteURL: String
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    let connectionOnly: Bool
    private let stores: StoresManager

    init(siteURL: String, connectionOnly: Bool, stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.connectionOnly = connectionOnly
        self.stores = stores
    }
}
