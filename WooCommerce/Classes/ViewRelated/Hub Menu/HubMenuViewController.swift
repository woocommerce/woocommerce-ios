import SwiftUI
import UIKit
import Yosemite

/// Displays a grid view of all available menu in the "Menu" tab (eg. View Store, Reviews, Coupons, etc...)
final class HubMenuViewController: UIHostingController<HubMenu> {
    private let viewModel: HubMenuViewModel

    init(siteID: Int64, navigationController: UINavigationController?) {
        self.viewModel = HubMenuViewModel(siteID: siteID, navigationController: navigationController)
        super.init(rootView: HubMenu(viewModel: viewModel))
        configureTabBarItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    /// Present the specific Review Details View from a push notification
    ///
    func pushReviewDetailsViewController(using parcel: ProductReviewFromNoteParcel) {
        viewModel.showReviewDetails(using: parcel)
    }

    func showPaymentsMenu() {
        show(InPersonPaymentsMenuViewController(), sender: self)
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
