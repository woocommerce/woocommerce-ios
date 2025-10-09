import SwiftUI
import struct Yosemite.Booking

struct BookingListContainerView: View {
    @ObservedObject private var viewModel: BookingListContainerViewModel
    @State private var isSearching = false
    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding var selectedBooking: Booking?

    init(viewModel: BookingListContainerViewModel, selectedBooking: Binding<Booking?>) {
        self.viewModel = viewModel
        self._selectedBooking = selectedBooking
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            TabView(selection: $viewModel.selectedTab) {
                ForEach(BookingListTab.allCases, id: \.rawValue) { tab in
                    BookingListView(
                        viewModel: viewModel.listViewModel(for: tab),
                        searchViewModel: viewModel.searchViewModel(for: tab),
                        selectedBooking: $selectedBooking
                    )
                    .tag(tab)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(Localization.viewTitle)
        .if(isSearching, transform: { view in
            view.searchable(text: $viewModel.searchQuery,
                            isPresented: $isSearching,
                            prompt: Localization.searchPrompt)
        })
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    withAnimation {
                        isSearching.toggle()
                        if !isSearching {
                            viewModel.searchQuery = ""
                        }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}

private extension BookingListContainerView {
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
                ForEach(BookingListTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.selectedTab = tab
                        }
                    } label: {
                        Text(tab.title)
                            .font(.subheadline)
                            .foregroundStyle(viewModel.selectedTab == tab ? Color.accentColor : Color.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .frame(height: Layout.topTabBarHeight * scale)
            .overlay(alignment: .bottom) {
                Color.accentColor
                    .frame(width: geometry.size.width / CGFloat(BookingListTab.allCases.count),
                           height: Layout.selectedTabIndicatorHeight * scale)
                    .offset(x: tabIndicatorOffset(containerWidth: geometry.size.width,
                                                  tabCount: BookingListTab.allCases.count,
                                                  selectedIndex: viewModel.selectedTab.rawValue),
                            y: Layout.selectedTabIndicatorHeight * scale / 2)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTab.rawValue)
            }
        }
        .frame(height: Layout.topTabBarHeight * scale)
        .background(Color(.listForeground(modal: false)))
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
private extension BookingListContainerView {
    enum Layout {
        static let topTabBarHeight: CGFloat = 44
        static let selectedTabIndicatorHeight: CGFloat = 3.0
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
        static let searchPrompt = NSLocalizedString(
            "bookingListView.search.prompt",
            value: "Search bookings",
            comment: "Prompt in the search bar on top of the booking list"
        )
    }
}
