import SwiftUI
import Combine
import struct Yosemite.Booking

/// Hosting view for `BookingsTabView`
///
final class BookingsTabViewHostingController: UIHostingController<BookingsTabView> {

    init(siteID: Int64) {
        super.init(rootView: BookingsTabView(siteID: siteID))
        configureTabBarItem()
    }

    @MainActor @preconcurrency dynamic required init?(coder aDecoder: NSCoder) {
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
    @State private var selectedBooking: Booking?
    @State private var visibility: NavigationSplitViewVisibility = .all
    @StateObject private var bookingListContainerViewModel: BookingListContainerViewModel
    @StateObject private var connectivityMonitor = ConnectivityMonitor()

    init(siteID: Int64) {
        _bookingListContainerViewModel = StateObject(wrappedValue: BookingListContainerViewModel(siteID: siteID))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            BookingListContainerView(viewModel: bookingListContainerViewModel, selectedBooking: $selectedBooking)
        } detail: {
            if let selectedBooking {
                let viewModel = BookingDetailsViewModel(booking: selectedBooking)
                NavigationStack {
                    BookingDetailsView(viewModel)
                }
            } else {
                Text("Select a booking to see details.")
            }
        }
        .navigationSplitViewStyle(.balanced)
        .safeAreaInset(edge: .bottom) {
            if connectivityMonitor.isOffline {
                OfflineBannerViewRepresentable()
                    .frame(height: OfflineBannerView.height)
            }
        }
        .onChange(of: selectedBooking) { _, newValue in
            bookingListContainerViewModel.selectedBookingChanged()
        }
    }
}
