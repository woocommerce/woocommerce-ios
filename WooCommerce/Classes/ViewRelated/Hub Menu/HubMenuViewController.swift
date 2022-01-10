import SwiftUI
import UIKit
import Yosemite

/// Displays a grid view of all available menu in the "Menu" tab (eg. View Store, Reviews, Coupons, etc...)
final class HubMenuViewController: UIHostingController<HubMenu> {

    init(siteID: Int64, navigationController: UINavigationController?) {
        super.init(rootView: HubMenu(siteID: siteID, navigationController: navigationController))
        configureNavigationBar()
        configureTabBarItem()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Present the specific Review Details View from a push notification
    ///
    func pushReviewDetailsViewController(using parcel: ProductReviewFromNoteParcel) {
        rootView.pushReviewDetailsView(using: parcel)
    }
}

private extension HubMenuViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
    }

    func configureTabBarItem() {
        tabBarItem.title = Localization.tabTitle
        tabBarItem.image = .hubMenu
        tabBarItem.accessibilityIdentifier = "tab-bar-menu-item"
    }
}

private extension HubMenuViewController {
    enum Localization {
        static let tabTitle = NSLocalizedString("Menu", comment: "Title of the Menu tab")
        static let navigationBarTitle =
            NSLocalizedString("Hub Menu",
                              comment: "Navigation bar title of hub menu view")
    }
}
