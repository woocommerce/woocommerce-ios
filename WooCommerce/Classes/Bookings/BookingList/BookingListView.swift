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
                            isSearching: false,
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
        VStack(spacing: 0) {
            if searchViewModel.isSearching {
                loadingView
            } else if searchViewModel.searchResults.isEmpty {
                header
                emptyStateView(isSearching: true) {
                    await searchViewModel.onRefreshAction()
                }
            } else {
                header
                bookingList(with: searchViewModel.searchResults,
                            isSearching: true,
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
                     isSearching: Bool,
                     onNextPage: @escaping () -> Void,
                     onRefresh: @escaping () async -> Void) -> some View {
        List(selection: $selectedBooking) {
            if isSearching {
                bookingListSection(with: bookings, onNextPage: onNextPage)
            } else {
                Section {
                    bookingListSection(with: bookings, onNextPage: onNextPage)
                } header: {
                    header
                        .listRowInsets(EdgeInsets())
                        .textCase(nil)
                }
            }
        }
        .apply {
            /// Plain list style in iOS prior to 26.0 comes with extra spacing at the top of header.
            /// Use grouped style for these versions instead.
            /// Grouped list style doesn't pin header at the top, we have to accept this.
            if #available(iOS 26.0, *) {
                $0.listStyle(.plain)
            } else {
                $0.listStyle(.grouped)
                    .scrollContentBackground(.hidden)
            }
        }
        .background(Color(.listBackground))
        .refreshable {
            await onRefresh()
        }
    }

    @ViewBuilder
    func bookingListSection(with bookings: [Booking], onNextPage: @escaping () -> Void) -> some View {
        ForEach(bookings) { item in
            bookingItem(item)
                .if(item == bookings.first) {
                    $0.listSectionSeparator(.hidden, edges: .top)
                }
                .tag(item)
        }

        InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
            .padding(.top, BookingListViewLayout.viewPadding)
            .onAppear {
                onNextPage()
            }
    }

    func bookingItem(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: BookingListViewLayout.bookingSummaryBadgeSpacing) {
            VStack(alignment: .leading, spacing: BookingListViewLayout.bookingSummarySpacing) {
                Text(booking.startDate.toString(dateStyle: .short,
                                                timeStyle: .short,
                                                timeZone: BookingListTab.utcTimeZone))
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Color.primary)

                if let productName = booking.productName {
                    Text(productName)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.secondary)
                }

                Text(booking.customerName)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)
            }

            HStack(spacing: BookingListViewLayout.bookingSummaryBadgeSpacing) {
                BookingBadgeView(booking.bookingItemHeaderStatusBadge)
                BookingBadgeView(booking.paymentStatusBadge)
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
                if isSearching {
                    emptyStateContent(isSearching: isSearching)
                        .frame(minWidth: proxy.size.width,
                               minHeight: proxy.size.height)
                } else {
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
    static let bookingSummarySpacing: CGFloat = 2
    static let bookingSummaryBadgeSpacing: CGFloat = 8
}

fileprivate enum BookingListViewLocalization {
    static let errorMessage = NSLocalizedString(
        "bookingList.errorMessage",
        value: "Error fetching bookings",
        comment: "Error message when fetching bookings fails"
    )
    static let emptySearchText = NSLocalizedString(
        "bookingList.emptySearchText.noDash",
        value: "We couldn't find any bookings with that name. Try adjusting your search term to see more results.",
        comment: "Message displayed when searching bookings by keyword yields no results. Version without a dash."
    )
    static let clearFilters = NSLocalizedString(
        "bookingList.clearFilters",
        value: "Clear filters",
        comment: "Button to clear the filters on booking list"
    )
}
