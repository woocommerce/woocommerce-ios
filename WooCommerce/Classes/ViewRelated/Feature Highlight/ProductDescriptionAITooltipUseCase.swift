import Foundation

struct ProductDescriptionAITooltipUseCase {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
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
    var shouldShowTooltip: Bool {
        numberOfTimesWriteWithAITooltipIsShown < 3 && !hasDismissedWriteWithAITooltip
    }
}
