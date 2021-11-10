import UIKit

struct SettingsFactory {
    /// Creates a Settings view controller
    ///
    static func settings() -> UIViewController {
        let viewModel = SettingsViewModel(stores: ServiceLocator.stores,
                                          storageManager: ServiceLocator.storageManager)
        let settingsViewController = SettingsViewController(viewModel: viewModel)
        viewModel.presenter = settingsViewController
        return settingsViewController
    }
}
