import SwiftUI
import UIKit

/// Displays a grid view of all available menu in the "Menu" tab (eg. View Store, Reviews, Coupons, etc...)
final class HubMenuViewController: UIHostingController<HubMenu> {
    init(siteID: Int64) {
        super.init(rootView: HubMenu())
        configureNavigationBar()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension HubMenuViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
        addCloseNavigationBarButton()
    }
}

private extension HubMenuViewController {
    enum Localization {
        static let navigationBarTitle =
            NSLocalizedString("Hub Menu title",
                              comment: "Navigation bar title of hub menu view")
    }
}
