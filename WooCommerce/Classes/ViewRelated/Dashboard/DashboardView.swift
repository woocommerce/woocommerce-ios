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

    private func configureTabBarItem() {
        tabBarItem.image = .statsAltImage
        tabBarItem.title = Localization.title
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }
}

private extension DashboardViewHostingController {
    enum Localization {
        static let title = NSLocalizedString(
            "dashboardView.title",
            value: "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
    }
}

/// View for the dashboard screen
///
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(siteID: Int64) {
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(siteID: siteID))
    }

    var body: some View {
        Text("Hello, World!")
    }
}

private extension DashboardView {
    // TODO
}

#Preview {
    DashboardView(siteID: 123)
}
