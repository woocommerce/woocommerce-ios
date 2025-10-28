import Foundation
import Yosemite

extension CIABEligibilityChecker {
    convenience init() {
        self.init(
            currentSite: {
                return ServiceLocator.stores.sessionManager.defaultSite
            }
        )
    }
}
