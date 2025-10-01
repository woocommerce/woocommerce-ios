import SwiftUI
import struct Yosemite.Booking

struct BookingListView<Header: View>: View {
    @ObservedObject private var viewModel: BookingListViewModel

    @Namespace var topID

    private let headerView: Header

    private let viewPadding: CGFloat = 16
    private let defaultBadgeColor = Color(uiColor: .init(light: .systemGray6, dark: .systemGray5))

    init(viewModel: BookingListViewModel,
         @ViewBuilder header: () -> Header) {
        self.viewModel = viewModel
        self.headerView = header()
    }

    var body: some View {
        VStack {
            switch viewModel.syncState {
            case .empty:
                headerView
                Spacer()
                Text("No bookings found") // TODO: update this in WOOMOB-1394
                Spacer()
            case .syncingFirstPage:
                headerView
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            case .results:
                bookingList
            }
        }
        .task {
            viewModel.loadBookings()
        }
    }
}

private extension BookingListView {
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
                        .padding(.top, viewPadding)
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
                    statusBadge(text: "Booked", color: defaultBadgeColor)
                    statusBadge(text: booking.bookingStatus.localizedTitle, color: defaultBadgeColor)
                    Spacer()
                }
            }
            .padding(viewPadding)

            Divider()
                .padding(.leading, viewPadding)
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
}
