import Foundation
import Yosemite

/// Protocol for checking "add product using AI" eligibility for easier unit testing.
protocol ProductCreationAIEligibilityCheckerProtocol {
    /// Checks if the user is eligible for the "add product using AI" feature.
    var isEligible: Bool { get }
}

/// Checks the eligibility for the "add product using AI" feature.
final class ProductCreationAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    var isEligible: Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }

        return site.isWordPressComStore || site.isAIAssistantFeatureActive
    }
}
