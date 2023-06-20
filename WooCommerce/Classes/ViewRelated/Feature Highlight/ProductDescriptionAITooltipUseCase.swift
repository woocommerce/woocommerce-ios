import Foundation

struct ProductDescriptionAITooltipUseCase {
    private let userStore: UserDefaults

    init(userStore: UserDefaults = UserDefaults.standard) {
        self.userStore = userStore
    }

    var didDismissTooltip: Bool {
        get {
            return userStore.bool(forKey: UserDefaults.Key.didUserDismissTooltip.rawValue)
        }
        set {
            userStore.set(newValue, forKey: UserDefaults.Key.didUserDismissTooltip.rawValue)
        }
    }

    var writeWithAITooltipCounter: Int {
        get {
            return userStore.integer(forKey: UserDefaults.Key.writeWithAITooltipCounter.rawValue)
        }
        set {
            userStore.set(newValue, forKey: UserDefaults.Key.writeWithAITooltipCounter.rawValue)
        }
    }

    /// Tooltip will only be shown 3 times if the user never interacts with it.
    var shouldShowTooltip: Bool {
        writeWithAITooltipCounter < 3 && !didDismissTooltip
    }
}
