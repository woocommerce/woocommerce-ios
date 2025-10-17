import SwiftUI
import struct Yosemite.Booking

struct BookingListView: View {
    @ObservedObject private var viewModel: BookingListViewModel
    @ObservedObject private var searchViewModel: BookingSearchViewModel

    @StateObject private var connectivityMonitor = ConnectivityMonitor()
    @ScaledMetric private var scale: CGFloat = 1.0

    @Binding var selectedBooking: Booking?

    init(viewModel: BookingListViewModel,
         searchViewModel: BookingSearchViewModel,
         selectedBooking: Binding<Booking?>) {
        self.viewModel = viewModel
        self.searchViewModel = searchViewModel
        self._selectedBooking = selectedBooking
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
            ForEach(bookings) { item in
                bookingItem(item)
                    .tag(item)
            }

            InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                .padding(.top, Layout.viewPadding)
                .onAppear {
                    onNextPage()
                }
        }
        .listStyle(.plain)
        .background(Color(.listBackground))
        .accentColor(Color(.listSelectedBackground))
        .refreshable {
            await onRefresh()
        }
    }

    func bookingItem(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
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
                    // TODO: update this when attendance status is available
                    // Update badge colors if design changes as statuses are not clarified now.
                    statusBadge(text: "Booked", color: Layout.defaultBadgeColor)
                    statusBadge(text: booking.bookingStatus.localizedTitle, color: Layout.defaultBadgeColor)
                    Spacer()
                }
            }
        }
    }

    func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.clipShape(RoundedRectangle(cornerRadius: 4)))
    }

    func emptyStateView(isSearching: Bool, onRefresh: @escaping () async -> Void) -> some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Layout.emptyStatePadding) {
                    Spacer()
                    Image(uiImage: isSearching ? .magnifyingGlassNotFound : .noBookings)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Layout.emptyStateImageWidth * scale)
                        .padding(.bottom, Layout.viewPadding)
                    if isSearching {
                        Text(Localization.emptySearchText)
                            .font(.body)
                            .foregroundStyle(Color.secondary)
                    } else {
                        VStack(spacing: Layout.textVerticalPadding) {
                            Text(viewModel.emptyStateTitle)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(viewModel.emptyStateDescription)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        if viewModel.hasFilters {
                            VStack(spacing: Layout.textVerticalPadding) {
                                Button("Change filters") {
                                    // TODO
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                Button("Clear filters") {
                                    // TODO
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                    }
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.emptyStatePadding)
                .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
            }
            .refreshable {
                await onRefresh()
            }
        }
        .background(Color(.systemBackground))
    }

    func errorSnackBar(onTap: @escaping () -> Void) -> some View {
        Text(Localization.errorMessage)
            .foregroundStyle(Color(.listForeground(modal: false)))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Layout.viewPadding)
            .background {
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .fill(Color(.text))
            }
            .padding(Layout.viewPadding)
            .padding(.bottom, connectivityMonitor.isOffline ? OfflineBannerView.height : 0)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
    }
}

private extension BookingListView {
    enum Layout {
        static let textVerticalPadding: CGFloat = 8
        static let viewPadding: CGFloat = 16
        static let emptyStatePadding: CGFloat = 24
        static let emptyStateImageWidth: CGFloat = 67
        static let defaultBadgeColor = Color(uiColor: .init(light: .systemGray6, dark: .systemGray5))
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let errorMessage = NSLocalizedString(
            "bookingList.errorMessage",
            value: "Error fetching bookings",
            comment: "Error message when fetching bookings fails"
        )
        static let emptySearchText = NSLocalizedString(
            "bookingList.emptySearchText",
            value: "We couldn’t find any bookings with that name — try adjusting your search term to see more results.",
            comment: "Message displayed when searching bookings by keyword yields no results."
        )
    }
}
