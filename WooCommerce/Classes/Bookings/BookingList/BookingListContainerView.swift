import SwiftUI
import struct Yosemite.Booking

struct BookingListContainerView: View {
    @ObservedObject private var viewModel: BookingListContainerViewModel
    @State private var isSearching = false
    @State private var showingSortOptions = false
    @State private var showingFilters = false

    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding var selectedBooking: Booking?

    init(viewModel: BookingListContainerViewModel, selectedBooking: Binding<Booking?>) {
        self.viewModel = viewModel
        self._selectedBooking = selectedBooking
    }

    var body: some View {
        BookingListView(
            viewModel: viewModel.listViewModel(for: viewModel.selectedTab),
            searchViewModel: viewModel.searchViewModel(for: viewModel.selectedTab),
            selectedBooking: $selectedBooking,
            header: { headerView },
            onClearingFilters: { viewModel.clearFilters() }
        )
        .navigationTitle(Localization.viewTitle)
        .if(isSearching, transform: { view in
            view.searchable(text: $viewModel.searchQuery,
                            isPresented: $isSearching,
                            prompt: Localization.searchPrompt)
        })
        .toolbar(removing: .sidebarToggle)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    withAnimation {
                        isSearching.toggle()
                        if !isSearching {
                            viewModel.searchQuery = ""
                        }
                        viewModel.searchTapped()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showingSortOptions) {
            sortingOptions
                .presentationDetents([.fraction(0.25), .medium, .large])
        }
        .sheet(isPresented: $showingFilters) {
            FilterListView(viewModel: viewModel.filterViewModel) { filters in
                viewModel.updateFilters(filters)
                viewModel.applyFiltersTapped()
                viewModel.onAppear()
            } onClearAction: {
                // no-op
            } onDismissAction: {
                viewModel.onAppear()
            }
        }
        .onAppear {
            viewModel.onAppear()
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
                    showingSortOptions = true
                    viewModel.sortByTapped()
                } label: {
                    Text(Localization.sortBy)
                        .font(.body)
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
                Button {
                    showingFilters = true
                    viewModel.filtersTapped()
                } label: {
                    Text(viewModel.filterText)
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
                            viewModel.setSelectedTab(to: tab)
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

    var sortingOptions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.SortingOptions.contentSpacing) {
                Text(Localization.sortBy)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                ForEach(BookingListViewModel.SortBy.allCases, id: \.rawValue) { sortBy in
                    Button {
                        viewModel.sortByOptionSelected(sortBy)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingSortOptions = false
                        }
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(sortBy.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(Color.accentColor)
                                .renderedIf(viewModel.sortBy == sortBy)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, Layout.SortingOptions.margin)
            .padding(.vertical, Layout.SortingOptions.topPadding)
        }
    }
}


private extension BookingListContainerView {
    enum Layout {
        static let topTabBarHeight: CGFloat = 44
        static let selectedTabIndicatorHeight: CGFloat = 3.0
        enum SortingOptions {
            static let contentSpacing: CGFloat = 24
            static let margin: CGFloat = 16
            static let topPadding: CGFloat = 52
        }
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
        static let searchPrompt = NSLocalizedString(
            "bookingListView.search.prompt",
            value: "Search bookings",
            comment: "Prompt in the search bar on top of the booking list"
        )
    }
}
