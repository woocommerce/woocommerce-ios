import SwiftUI
import UIKit
import Yosemite

/// Displays a grid view of all available menu in the "Menu" tab (eg. View Store, Reviews, Coupons, etc...)
final class HubMenuViewController: UIHostingController<HubMenu> {
    private let viewModel: HubMenuViewModel
    private let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

    private var storePickerCoordinator: StorePickerCoordinator?

    init(siteID: Int64,
         navigationController: UINavigationController?,
         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker) {
        self.viewModel = HubMenuViewModel(siteID: siteID,
                                          tapToPayBadgePromotionChecker: tapToPayBadgePromotionChecker)
        self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker
        super.init(rootView: HubMenu(viewModel: viewModel))
        configureTabBarItem()
        rootView.switchStoreHandler = { [weak self] in
            self?.presentSwitchStore()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear()
    }

    /// Present the specific Review Details View from a push notification
    ///
    func pushReviewDetailsViewController(using parcel: ProductReviewFromNoteParcel) {
        viewModel.showReviewDetails(using: parcel)
    }

    func showPaymentsMenu() {
        viewModel.showPayments()
    }

    func showCoupons() {
        viewModel.showingCoupons = true
    }

    /// Pushes the Settings & Privacy screen onto the navigation stack.
    ///
    func showPrivacySettings() {
        guard let navigationController else {
            return DDLogError("⛔️ Could not find a navigation controller context.")
        }
        guard let privacy = UIStoryboard.dashboard.instantiateViewController(ofClass: PrivacySettingsViewController.self) else {
            return DDLogError("⛔️ Could not instantiate PrivacySettingsViewController")
        }

        let settings = SettingsViewController()
        navigationController.setViewControllers(navigationController.viewControllers + [settings, privacy], animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // We want to hide navigation bar *only* on HubMenu screen. But on iOS 16, the `navigationBarHidden(true)`
        // modifier on `HubMenu` view hides the navigation bar for the whole navigation stack.
        // Here we manually hide or show navigation bar when entering or leaving the HubMenu screen.
        if #available(iOS 16.0, *) {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if #available(iOS 16.0, *) {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
}

private extension HubMenuViewController {
    /// Present the `StorePickerViewController` using the `StorePickerCoordinator`, passing the navigation controller from the entry point.
    ///
    func presentSwitchStore() {
        if let navigationController = navigationController {
            storePickerCoordinator = StorePickerCoordinator(navigationController, config: .switchingStores)
            storePickerCoordinator?.start()
        }
    }
}

extension HubMenuViewController: DeepLinkNavigator {
    func navigate(to destination: any DeepLinkDestinationProtocol) {
        switch destination {
        case is PaymentsMenuDestination:
            showPaymentsMenu()
            viewModel.inPersonPaymentsMenuViewModel.navigate(to: destination)
        case is HubMenuDestination:
            handleHubMenuDeepLink(to: destination)
        default:
            break
        }
    }

    private func handleHubMenuDeepLink(to destination: any DeepLinkDestinationProtocol) {
        guard let hubMenuDestination = destination as? HubMenuDestination else {
            return
        }
        switch hubMenuDestination {
        case .paymentsMenu:
            showPaymentsMenu()
        }
    }
}

private extension HubMenuViewController {
    func configureTabBarItem() {
        tabBarItem.title = Localization.tabTitle
        tabBarItem.image = .hubMenu
        tabBarItem.accessibilityIdentifier = "tab-bar-menu-item"
    }
}

private extension HubMenuViewController {
    enum Localization {
        static let tabTitle = NSLocalizedString("Menu", comment: "Title of the Menu tab")
    }
}
