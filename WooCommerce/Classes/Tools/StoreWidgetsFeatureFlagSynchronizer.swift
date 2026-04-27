import Foundation
import Experiments
import class WidgetKit.WidgetCenter

enum StoreWidgetsFeatureFlagSynchronizer {
    static func sync() {
        guard let userDefaults = UserDefaults.group else { return }

        let isEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.configurableStoreStatsWidgets)
        let currentValue: Bool? = userDefaults.object(forKey: .configurableStoreStatsWidgetsEnabled)
        guard currentValue != isEnabled else { return }

        userDefaults.configurableStoreStatsWidgetsEnabled = isEnabled
        WidgetCenter.shared.reloadAllTimelines()
    }
}
