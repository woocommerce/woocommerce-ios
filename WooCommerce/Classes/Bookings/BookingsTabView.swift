import SwiftUI
import Combine

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
    @StateObject private var connectivityMonitor = ConnectivityMonitor()
    @StateObject private var containerViewModel: BookingListContainerViewModel

    init(siteID: Int64) {
        _containerViewModel = StateObject(wrappedValue: BookingListContainerViewModel(siteID: siteID))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            BookingListContainerView(viewModel: containerViewModel)
        } detail: {
            Text("Booking Detail Screen")
        }
        .navigationSplitViewStyle(.balanced)
        .safeAreaInset(edge: .bottom) {
            if connectivityMonitor.isOffline {
                OfflineBannerViewRepresentable()
                    .frame(height: OfflineBannerView.height)
            }
        }
    }
}
