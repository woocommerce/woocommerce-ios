import SwiftUI

/// Hosting view for `BookingsTabView`
///
final class BookingsTabViewHostingController: UIHostingController<BookingsTabView> {
    // periphery: ignore
    init(siteID: Int64) {
        super.init(rootView: BookingsTabView())
        configureTabBarItem()
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }
}

private extension BookingsTabViewHostingController {
    func configureTabBarItem() {
        tabBarItem.image = UIImage(systemName: "calendar")
        tabBarItem.title = "Bookings"
        tabBarItem.accessibilityIdentifier = "tab-bar-bookings-item"
    }
}

/// Main content of the Bookings tab
///
struct BookingsTabView: View {
    @State private var visibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            Text("Booking List")
        } detail: {
            Text("Booking Detail Screen")
        }
        .navigationSplitViewStyle(.balanced)
    }
}
