import SwiftUI
import struct Yosemite.Booking

struct BookingListView: View {
    @ObservedObject private var viewModel: BookingListViewModel
    @State private var selectedTabIndex = 0

    @Namespace var topID

    private let tabs = [Localization.today, Localization.upcoming, Localization.all]

    init(viewModel: BookingListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.syncState {
                case .empty:
                    headerView
                    Spacer()
                    Text("No bookings found") // TODO: update this in WOOMOB-1394
                    Spacer()
                case .syncingFirstPage:
                    headerView
                    ProgressView().progressViewStyle(.circular)
                case .results:
                    bookingList
                }
            }
            .navigationTitle(Localization.viewTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        // TODO
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .task {
                viewModel.loadBookings()
            }
        }
    }
}

private extension BookingListView {
    var headerView: some View {
        VStack(spacing: 0) {
            topTabView
            Divider()
            HStack {
                Button {
                    // TODO
                } label: {
                    Text(Localization.sortBy)
                        .font(.body)
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
                Button {
                    // TODO
                } label: {
                    Text(Localization.filter)
                        .font(.body)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(Color(.listForeground(modal: false)))
            Divider()
        }
    }

    var topTabView: some View {
        GeometryReader { geometry in
            HStack {
                ForEach(Array(tabs.enumerated()), id: \.element) { (index, title) in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTabIndex = index
                        }
                    } label: {
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(selectedTabIndex == index ? Color.accentColor : Color.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .overlay(alignment: .bottom) {
                Color.accentColor
                    .frame(width: geometry.size.width / CGFloat(tabs.count),
                           height: Layout.selectedTabIndicatorHeight)
                    .offset(x: tabIndicatorOffset(containerWidth: geometry.size.width,
                                                  tabCount: tabs.count,
                                                  selectedIndex: selectedTabIndex))
                    .animation(.easeInOut(duration: 0.3), value: selectedTabIndex)
            }
        }
        .frame(height: Layout.topTabBarHeight)
        .background(Color(.listForeground(modal: false)))
    }

    var bookingList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        ForEach(viewModel.bookings) { item in
                            bookingItem(item)
                        }
                    } header: {
                        headerView
                    }
                    .id(topID)

                    InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                        .padding(.top, Layout.viewPadding)
                        .onAppear {
                            viewModel.onLoadNextPageAction()
                        }
                }
            }
            .refreshable {
                await viewModel.onRefreshAction()
                // workaround as navigation bar is not snapped back after refreshing
                proxy.scrollTo(topID, anchor: .top)
            }
        }
    }

    func bookingItem(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text(booking.startDate.formatted(date: .numeric, time: .shortened))
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // TODO: fetch bookable products & customer to get names or wait for API update
                Text(String(format: "%@  •  %@", "Women's Hair cut", "Marianne"))
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)

                HStack {
                    // TODO: update this when attendance status is available
                    // Update badge colors if design changes as statuses are not clarified now.
                    statusBadge(text: "Booked", color: Layout.defaultBadgeColor)
                    statusBadge(text: booking.bookingStatus.localizedTitle, color: Layout.defaultBadgeColor)
                    Spacer()
                }
            }
            .padding(Layout.viewPadding)

            Divider()
                .padding(.leading, Layout.viewPadding)
        }
        .background(Color(.listForeground(modal: false))) // TODO: update selected background color as part of selection handling
    }

    func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.clipShape(RoundedRectangle(cornerRadius: 4)))
    }

    /// SwiftUI's coordinate system places (0,0) at the center of the container, so we need to:
    /// 1. Calculate how far the selected tab is from the left edge
    /// 2. Adjust for the center-based coordinate system
    /// 3. Center the indicator within the selected tab
    ///
    func tabIndicatorOffset(containerWidth: CGFloat, tabCount: Int, selectedIndex: Int) -> CGFloat {
        let tabWidth = containerWidth / CGFloat(tabCount)
        let distanceFromLeftEdge = tabWidth * CGFloat(selectedIndex)
        let adjustmentForCenterOrigin = containerWidth / 2
        let centerWithinTab = tabWidth / 2

        return distanceFromLeftEdge - adjustmentForCenterOrigin + centerWithinTab
    }
}
private extension BookingListView {
    enum Layout {
        static let viewPadding: CGFloat = 16
        static let topTabBarHeight: CGFloat = 44
        static let selectedTabIndicatorHeight: CGFloat = 3.0
        static let defaultBadgeColor = Color(uiColor: .init(light: .systemGray6, dark: .systemGray5))
    }

    enum Localization {
        static let viewTitle = NSLocalizedString(
            "bookingListView.view.title",
            value: "Bookings",
            comment: "Title of the booking list view"
        )
        static let sortBy = NSLocalizedString(
            "bookingListView.sortBy",
            value: "Sort by",
            comment: "Button to select the order of the booking list"
        )
        static let filter = NSLocalizedString(
            "bookingListView.filter",
            value: "Filter",
            comment: "Button to filter the booking list"
        )
        static let today = NSLocalizedString(
            "bookingListView.today",
            value: "Today",
            comment: "Tab title for today's bookings"
        )
        static let upcoming = NSLocalizedString(
            "bookingListView.upcoming",
            value: "Upcoming",
            comment: "Tab title for upcoming bookings"
        )
        static let all = NSLocalizedString(
            "bookingListView.all",
            value: "All",
            comment: "Tab title for all bookings"
        )
    }
}

#Preview {
    BookingListView(viewModel: BookingListViewModel(siteID: 123))
}
