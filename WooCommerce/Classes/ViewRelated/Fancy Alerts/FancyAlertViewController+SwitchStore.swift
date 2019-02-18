import WordPressUI
import Yosemite

/// Encapsulates the logic that decides when the fancy alert informing that users can switch stores is presented.
/// The fancy alert will be presented only once.
///
final class SwitchStoreAlertLauncher {
    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private let resultsController: ResultsController<StorageSite> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "isWooCommerceActive == YES")
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    func displayStoreSwitcherAlertIfNeeded() {
        guard shouldPresentStoreSwitcher() else {
            return
        }

        displayStoreSwitcherAlert()
    }

    private func shouldPresentStoreSwitcher() -> Bool {
//        guard StoresManager.shared.isAuthenticated else {
//            return false
//        }
//
//        guard userHasMultipleStores() else {
//            return false
//        }
//
//        let alertPresented = UserDefaults.standard[.storeSwitcherAlertPresented] as? Bool ?? false
//
//        return alertPresented == false

        return true
    }

    private func userHasMultipleStores() -> Bool {
        try? resultsController.performFetch()
        return resultsController.fetchedObjects.count > 1
    }

    private func displayStoreSwitcherAlert() {
        let fancyAlert = FancyAlertViewController.makeSwitchStoreAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        AppDelegate.shared.tabBarController?.present(fancyAlert, animated: true)

        UserDefaults.standard[.storeSwitcherAlertPresented] = true
    }
}


public extension FancyAlertViewController {

    /// Create the fancy alert controller for the alert informing that users can switch stores in Settings.
    ///
    /// - Returns: FancyAlertViewController of the alert
    ///
    static func makeSwitchStoreAlertController() -> FancyAlertViewController {

        let defaultButton = makePrimaryButton()
        let dismissButton = makeSecondaryButton()

        let image = UIImage(named: "woo-store-switcher")
//        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
//                                                     bodyText: Strings.bodyText,
//                                                     headerImage: image,
//                                                     dividerPosition: .bottom,
//                                                     defaultButton: defaultButton,
//                                                     cancelButton: dismissButton,
//                                                     neverButton: nil,
//                                                     appearAction: {},
//                                                     dismissAction: {})
        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: defaultButton,
                                                     cancelButton: dismissButton,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}


// MARK: - Private Helpers
//
private extension FancyAlertViewController {

    static func makeSecondaryButton() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Strings.dismissButtonText) { controller, _ in
            controller.dismiss(animated: true)
        }
    }

    static func makePrimaryButton() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Strings.tryNowButtonText) { controller, _ in
            controller.dismiss(animated: true)
            MainTabBarController.presentSettings()
        }
    }
}


// MARK: - Constants
//
private extension FancyAlertViewController {

    struct Strings {
        // Title
        static let titleText = NSLocalizedString("Running multiple stores?",
                                                          comment: "Title of alert informing users that it is possible to switch stores in Settings.")
        // Body
        static let bodyText = NSLocalizedString("You can now switch between stores by tapping the selected store in Settings.",
                                                          comment: "Body text of alert informing users that it is possible to switch stores in Settings.")

        // UI Elements
        static let dismissButtonText = NSLocalizedString("Got It", comment: "Dismiss button in alert informing users that it is possible to switch stores in settings.")
        static let tryNowButtonText = NSLocalizedString("Try It Now", comment: "Primary button in alert informing users that it is possible to switch stores in settings and inviting them to do so.")
    }
}
