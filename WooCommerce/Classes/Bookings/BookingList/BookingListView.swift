import SwiftUI
import struct Yosemite.Booking

struct BookingListView<Header: View>: View {
    @ObservedObject private var viewModel: BookingListViewModel
    @ObservedObject private var searchViewModel: BookingSearchViewModel

    @StateObject private var connectivityMonitor = ConnectivityMonitor()
    @ScaledMetric private var scale: CGFloat = 1.0

    @Binding var selectedBooking: Booking?

    private let header: Header
    private let onClearingFilters: (() -> Void)?

    init(viewModel: BookingListViewModel,
         searchViewModel: BookingSearchViewModel,
         selectedBooking: Binding<Booking?>,
         @ViewBuilder header: () -> Header,
         onClearingFilters: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.searchViewModel = searchViewModel
        self._selectedBooking = selectedBooking
        self.header = header()
        self.onClearingFilters = onClearingFilters
    }

    var body: some View {
        mainContentView
            .task {
                viewModel.loadBookings()
            }
            .overlay {
                searchContentView
                    .renderedIf(searchViewModel.currentSearchQuery.isNotEmpty)
            }
    }
}

private extension BookingListView {
    var mainContentView: some View {
        VStack {
            switch viewModel.syncState {
            case .empty:
                emptyStateView(isSearching: false) {
                    await viewModel.onRefreshAction()
                }
            case .syncingFirstPage:
                loadingView
            case .results:
                bookingList(with: viewModel.bookings,
                            onNextPage: { viewModel.onLoadNextPageAction() },
                            onRefresh: { await viewModel.onRefreshAction() })
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.errorFetching {
                errorSnackBar(onTap: {
                    withAnimation {
                        viewModel.errorFetching = false
                    }
                })
                .transition(.move(edge: .bottom))
            }
        }
    }

    var searchContentView: some View {
        VStack {
            if searchViewModel.isSearching {
                loadingView
            } else if searchViewModel.searchResults.isEmpty {
                emptyStateView(isSearching: true) {
                    await searchViewModel.onRefreshAction()
                }
            } else {
                bookingList(with: searchViewModel.searchResults,
                            onNextPage: { searchViewModel.onLoadNextPageAction() },
                            onRefresh: { await searchViewModel.onRefreshAction() })
            }
        }
        .overlay(alignment: .bottom) {
            if searchViewModel.errorFetching {
                errorSnackBar(onTap: {
                    withAnimation {
                        searchViewModel.errorFetching = false
                    }
                })
                .transition(.move(edge: .bottom))
            }
        }
    }

    var loadingView: some View {
        VStack {
            header
            Spacer()
            ProgressView().progressViewStyle(.circular)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    func bookingList(with bookings: [Booking],
                     onNextPage: @escaping () -> Void,
                     onRefresh: @escaping () async -> Void) -> some View {
        List(selection: $selectedBooking) {
            Section {
                ForEach(bookings) { item in
                    bookingItem(item)
                        .tag(item)
                }

                InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                    .padding(.top, BookingListViewLayout.viewPadding)
                    .onAppear {
                        onNextPage()
                    }
            } header: {
                header
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden, edges: .top)
        .background(Color(.listBackground))
        .refreshable {
            await onRefresh()
        }
    }

    func bookingItem(_ booking: Booking) -> some View {
        VStack(alignment: .leading) {
            Text(booking.startDate.toString(dateStyle: .short,
                                            timeStyle: .short,
                                            timeZone: BookingListTab.utcTimeZone))
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Color.primary)

            Text(booking.summaryText)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(Color.secondary)

            HStack {
                BookingBadgeView(booking.attendanceStatus)
                BookingBadgeView(booking.bookingStatus)
                Spacer()
            }
        }
        .padding()
        .background(
            (booking == selectedBooking ? Color(.listSelectedBackground) : Color(.listForeground(modal: false)))
        )
        .listRowInsets(.init())
    }

    func emptyStateView(isSearching: Bool, onRefresh: @escaping () async -> Void) -> some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        emptyStateContent(isSearching: isSearching)
                            .frame(minWidth: proxy.size.width,
                                   minHeight: proxy.size.height - BookingListViewLayout.defaultHeaderHeight * scale)
                    } header: {
                        header
                    }
                }
            }
            .refreshable {
                await onRefresh()
            }
        }
        .background(Color(.systemBackground))
    }

    func emptyStateContent(isSearching: Bool) -> some View {
        VStack(spacing: BookingListViewLayout.emptyStatePadding) {
            Spacer()
            Image(uiImage: isSearching ? .magnifyingGlassNotFound : .noBookings)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: BookingListViewLayout.emptyStateImageWidth * scale)
                .padding(.bottom, BookingListViewLayout.viewPadding)
            if isSearching {
                Text(BookingListViewLocalization.emptySearchText)
                    .font(.body)
                    .foregroundStyle(Color.secondary)
            } else {
                VStack(spacing: BookingListViewLayout.textVerticalPadding) {
                    Text(viewModel.emptyStateTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(viewModel.emptyStateDescription)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                if viewModel.hasFilters {
                    VStack(spacing: BookingListViewLayout.textVerticalPadding) {
                        Button(BookingListViewLocalization.clearFilters) {
                            onClearingFilters?()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, BookingListViewLayout.emptyStatePadding)
    }

    func errorSnackBar(onTap: @escaping () -> Void) -> some View {
        Text(BookingListViewLocalization.errorMessage)
            .foregroundStyle(Color(.listForeground(modal: false)))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BookingListViewLayout.viewPadding)
            .background {
                RoundedRectangle(cornerRadius: BookingListViewLayout.cornerRadius)
                    .fill(Color(.text))
            }
            .padding(BookingListViewLayout.viewPadding)
            .padding(.bottom, connectivityMonitor.isOffline ? OfflineBannerView.height : 0)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
    }
}

fileprivate enum BookingListViewLayout {
    static let textVerticalPadding: CGFloat = 8
    static let viewPadding: CGFloat = 16
    static let emptyStatePadding: CGFloat = 24
    static let emptyStateImageWidth: CGFloat = 67
    static let cornerRadius: CGFloat = 8
    static let defaultHeaderHeight: CGFloat = 98
}

fileprivate enum BookingListViewLocalization {
    static let errorMessage = NSLocalizedString(
        "bookingList.errorMessage",
        value: "Error fetching bookings",
        comment: "Error message when fetching bookings fails"
    )
    static let emptySearchText = NSLocalizedString(
        "bookingList.emptySearchText",
        value: "We couldn't find any bookings with that name — try adjusting your search term to see more results.",
        comment: "Message displayed when searching bookings by keyword yields no results."
    )
    static let clearFilters = NSLocalizedString(
        "bookingList.clearFilters",
        value: "Clear filters",
        comment: "Button to clear the filters on booking list"
    )
}
