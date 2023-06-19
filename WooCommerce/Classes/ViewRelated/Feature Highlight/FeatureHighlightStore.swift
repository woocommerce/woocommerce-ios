import Foundation

struct FeatureHighlightStore {
    private enum Keys {
        static let didUserDismissTooltipKey = "did-user-dismiss-tooltip-key"
        static let writeWithAITooltipCounterKey = "write-with-ai-tooltip-counter"
    }

    private let userStore: UserDefaults

    init(userStore: UserDefaults = UserDefaults.standard) {
        self.userStore = userStore
    }

    var didDismissTooltip: Bool {
        get {
            return userStore.bool(forKey: Keys.didUserDismissTooltipKey)
        }
        set {
            userStore.set(newValue, forKey: Keys.didUserDismissTooltipKey)
        }
    }

    var writeWithAITooltipCounter: Int {
        get {
            return userStore.integer(forKey: Keys.writeWithAITooltipCounterKey)
        }
        set {
            userStore.set(newValue, forKey: Keys.writeWithAITooltipCounterKey)
        }
    }

    /// Tooltip will only be shown 3 times if the user never interacts with it.
    var shouldShowTooltip: Bool {
        writeWithAITooltipCounter < 3 && !didDismissTooltip
    }
}
