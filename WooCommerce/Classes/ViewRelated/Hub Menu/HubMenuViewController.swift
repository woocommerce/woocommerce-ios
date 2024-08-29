import SwiftUI
import UIKit
import Yosemite

/// Displays a grid view of all available menu in the "Menu" tab (eg. View Store, Reviews, Coupons, etc...)
final class HubMenuViewController: UIHostingController<HubMenu> {
    private let viewModel: HubMenuViewModel
    private let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

    private var storePickerCoordinator: StorePickerCoordinator?
    private var googleAdsCampaignCoordinator: GoogleAdsCampaignCoordinator?

    private var shouldShowNavigationBar = false

    init(siteID: Int64,
         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker) {
        self.viewModel = HubMenuViewModel(siteID: siteID,
                                          tapToPayBadgePromotionChecker: tapToPayBadgePromotionChecker)

        self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker
        super.init(rootView: HubMenu(viewModel: viewModel))
        configureTabBarItem()

        rootView.switchStoreHandler = { [weak self] in
            self?.presentSwitchStore()
        }

        rootView.googleAdsCampaignHandler = { [weak self] in
            self?.presentGoogleAds()
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
        viewModel.navigateToDestination(.coupons)
    }

    /// Pushes the Settings & Privacy screen onto the navigation stack.
    ///
    func showPrivacySettings() {
        guard let navigationController else {
            return DDLogError("⛔️ Could not find a navigation controller context.")
        }
        guard let privacy = UIStoryboard.settings.instantiateViewController(ofClass: PrivacySettingsViewController.self) else {
            return DDLogError("⛔️ Could not instantiate PrivacySettingsViewController")
        }

        let settings = SettingsViewController()
        navigationController.setViewControllers(navigationController.viewControllers + [settings, privacy], animated: true)
        navigationController.setNavigationBarHidden(false, animated: false)
        shouldShowNavigationBar = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Skip hiding navigation bar when `shouldShowNavigationBar` is set to true.
        guard !shouldShowNavigationBar else {
            shouldShowNavigationBar = false
            return
        }

        // We want to hide navigation bar *only* on HubMenu screen. But on iOS 16, the `navigationBarHidden(true)`
        // modifier on `HubMenu` view hides the navigation bar for the whole navigation stack.
        // Here we manually hide or show navigation bar when entering or leaving the HubMenu screen.
        navigationController?.setNavigationBarHidden(true, animated: animated)
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

    func presentGoogleAds() {
        guard let navigationController else {
            return
        }
        googleAdsCampaignCoordinator = GoogleAdsCampaignCoordinator(
            siteID: viewModel.siteID,
            siteAdminURL: viewModel.woocommerceAdminURL.absoluteString,
            source: .moreMenu,
            shouldStartCampaignCreation: viewModel.hasGoogleAdsCampaigns,
            shouldAuthenticateAdminPage: viewModel.shouldAuthenticateAdminPage,
            navigationController: navigationController,
            onCompletion: { [weak self] createdNewCampaign in
                guard createdNewCampaign else {
                    return
                }
                self?.viewModel.refreshGoogleAdsCampaignCheck()
            }
        )
        googleAdsCampaignCoordinator?.start()

        ServiceLocator.analytics.track(event: .GoogleAds.entryPointTapped(
            source: .moreMenu,
            type: viewModel.hasGoogleAdsCampaigns ? .dashboard : .campaignCreation,
            hasCampaigns: viewModel.hasGoogleAdsCampaigns
        ))
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
