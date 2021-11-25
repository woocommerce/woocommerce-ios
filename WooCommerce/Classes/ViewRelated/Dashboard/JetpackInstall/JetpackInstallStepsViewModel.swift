import Combine
import Foundation
import Yosemite

/// View model for `JetpackInstallStepsView`
///
final class JetpackInstallStepsViewModel: ObservableObject {
    /// ID of the site to install Jetpack-the-plugin to.
    ///
    private let siteID: Int64

    /// Stores manager to handle install steps.
    ///
    private let stores: StoresManager
    
    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }
}
