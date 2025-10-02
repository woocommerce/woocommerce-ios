import SwiftUI

/// Hosting view for `BookingsTabView`
///
final class BookingsTabViewHostingController: UIHostingController<BookingsTabView> {

    init(siteID: Int64) {
        super.init(rootView: BookingsTabView(siteID: siteID))
        configureTabBarItem()
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }

    func didSwitchStore(id: Int64) {
        rootView = BookingsTabView(siteID: id)
    }
}

private extension BookingsTabViewHostingController {
    func configureTabBarItem() {
        tabBarItem.image = UIImage(systemName: "calendar")
        tabBarItem.title = NSLocalizedString(
            "bookingsTabViewHostingController.tab.title",
            value: "Bookings",
            comment: "Title of the Bookings tab"
        )
        tabBarItem.accessibilityIdentifier = "tab-bar-bookings-item"
    }
}

/// Main content of the Bookings tab
///
struct BookingsTabView: View {
    @State private var visibility: NavigationSplitViewVisibility = .all

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            BookingListContainerView(viewModel: BookingListContainerViewModel(siteID: siteID))
        } detail: {
            Text("Booking Detail Screen")
        }
        .navigationSplitViewStyle(.balanced)
    }
}
