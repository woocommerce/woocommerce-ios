import Foundation
import Experiments

struct ProductDescriptionAITooltipUseCase {
    private let userDefaults: UserDefaults
    private let featureFlagService: FeatureFlagService
    private let isDescriptionAIEnabled: Bool

    init(userDefaults: UserDefaults = UserDefaults.standard,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         isDescriptionAIEnabled: Bool) {
        self.userDefaults = userDefaults
        self.featureFlagService = featureFlagService
        self.isDescriptionAIEnabled = isDescriptionAIEnabled
    }

    var hasDismissedWriteWithAITooltip: Bool {
        get {
            userDefaults.bool(forKey: UserDefaults.Key.hasDismissedWriteWithAITooltip.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: UserDefaults.Key.hasDismissedWriteWithAITooltip.rawValue)
        }
    }

    var numberOfTimesWriteWithAITooltipIsShown: Int {
        get {
            userDefaults.integer(forKey: UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown.rawValue)
        }
    }

    /// Tooltip will only be shown 3 times if the user never interacts with it.
    func shouldShowTooltip(for product: ProductFormDataModel) -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.productDescriptionAIFromStoreOnboarding) else {
            return false
        }

        guard isDescriptionAIEnabled else {
            return false
        }

        guard product.description?.isEmpty == true else {
            return false
        }

        return numberOfTimesWriteWithAITooltipIsShown < 3 && !hasDismissedWriteWithAITooltip
    }
}
