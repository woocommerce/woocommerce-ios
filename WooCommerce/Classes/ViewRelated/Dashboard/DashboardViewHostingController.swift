import SwiftUI

/// Hosting view for `DashboardView`
///
final class DashboardViewHostingController: UIHostingController<DashboardView> {
    init(siteID: Int64) {
        super.init(rootView: DashboardView(siteID: siteID))
        configureTabBarItem()
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerUserActivity()
    }
}

// MARK: Private helpers
private extension DashboardViewHostingController {
    func configureTabBarItem() {
        tabBarItem.image = .statsAltImage
        tabBarItem.title = Localization.title
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }
}

private extension DashboardViewHostingController {
    enum Localization {
        static let title = NSLocalizedString(
            "dashboardViewHostingController.title",
            value: "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
    }
}

// MARK: - SearchableActivity Conformance
extension DashboardViewHostingController: SearchableActivityConvertible {
    var activityType: String {
        return WooActivityType.dashboard.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("My Store", comment: "Title of the 'My Store' tab - used for spotlight indexing on iOS.")
    }

    var activityDescription: String? {
        return NSLocalizedString("See at a glance which products are winning.",
                                 comment: "Description of the 'My Store' screen - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("woocommerce, my store, today, this week, this month, this year," +
                                              "orders, visitors, conversion, top conversion, items sold",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Dashboard' tab.")
        return keyWordString.setOfTags()
    }
}
