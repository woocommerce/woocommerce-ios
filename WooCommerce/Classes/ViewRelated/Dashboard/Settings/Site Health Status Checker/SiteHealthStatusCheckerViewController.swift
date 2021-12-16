import SwiftUI
import UIKit

/// Displays the initial view of the Site Health Status Checker utility
final class SiteHealthStatusCheckerViewController: UIHostingController<SiteHealthStatusChecker> {
    init(siteID: Int64) {
        super.init(rootView: SiteHealthStatusChecker(siteID: siteID))
        configureNavigationBar()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SiteHealthStatusCheckerViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
    }
}

private extension SiteHealthStatusCheckerViewController {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Site Health Status Checker", comment: "Navigation bar title of the Site Health Status Checker view")
    }
}
